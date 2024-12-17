//
//  ContentView.swift
//  FlappyBird
//
//  Created by Om Preetham Bandi on 12/15/24.
//

import SwiftUI
import Combine

// MARK: - Models

struct Bird {
    var x: CGFloat = 100
    var y: CGFloat = UIScreen.main.bounds.height / 2
    let size: CGSize = CGSize(width: 40, height: 40)
}

struct Pipe: Identifiable {
    let id = UUID()
    var x: CGFloat
    let gapY: CGFloat
    let gapHeight: CGFloat = 180
    let width: CGFloat = 60
    
    // Top pipe rect
    var topRect: CGRect {
        CGRect(x: x, y: 0, width: width, height: gapY - gapHeight/2)
    }
    // Bottom pipe rect
    var bottomRect: CGRect {
        CGRect(x: x, y: gapY + gapHeight/2, width: width, height: UIScreen.main.bounds.height - (gapY + gapHeight/2))
    }
}

// MARK: - ViewModel

class GameViewModel: ObservableObject {
    @Published var bird = Bird()
    @Published var pipes: [Pipe] = []
    @Published var score: Int = 0
    @Published var gameOver: Bool = false
    @Published var isPlaying: Bool = false
    
    // Physics
    private let gravity: CGFloat = 0.6
    private let jumpVelocity: CGFloat = -10
    private var birdVelocity: CGFloat = 0
    
    private var timer: AnyCancellable?
    
    init() {
        resetGame()
    }
    
    func resetGame() {
        bird = Bird()
        pipes = []
        score = 0
        birdVelocity = 0
        gameOver = false
        isPlaying = false
        
        // Generate initial pipes
        for i in 0..<3 {
            let xPos = UIScreen.main.bounds.width + CGFloat(i*300)
            pipes.append(randomPipe(x: xPos))
        }
    }
    
    func startGame() {
        isPlaying = true
        timer = Timer.publish(every: 1/60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.gameLoop()
            }
    }
    
    func gameLoop() {
        guard !gameOver else { return }
        
        // Update bird
        birdVelocity += gravity
        bird.y += birdVelocity
        
        // Move pipes
        for i in pipes.indices {
            pipes[i].x -= 3
        }
        
        // Recycle pipes
        if let firstPipe = pipes.first, firstPipe.x < -firstPipe.width {
            pipes.removeFirst()
            let newPipeX = pipes.last!.x + 200
            pipes.append(randomPipe(x: newPipeX))
        }
        
        // Check collisions
        checkCollisions()
    }
    
    func flap() {
        guard !gameOver else {
            // If game over, restart on tap
            resetGame()
            startGame()
            return
        }
        if !isPlaying {
            startGame()
        }
        birdVelocity = jumpVelocity
    }
    
    func randomPipe(x: CGFloat) -> Pipe {
        let gapY = CGFloat.random(in: 150...(UIScreen.main.bounds.height-150))
        return Pipe(x: x, gapY: gapY)
    }
    
    func checkCollisions() {
        // Bird rect
        let birdRect = CGRect(x: bird.x - bird.size.width/2,
                              y: bird.y - bird.size.height/2,
                              width: bird.size.width,
                              height: bird.size.height)
        
        // Check top/bottom screen collision
        if birdRect.minY < 0 || birdRect.maxY > UIScreen.main.bounds.height {
            endGame()
        }
        
        // Check pipe collisions
        for pipe in pipes {
            if birdRect.intersects(pipe.topRect) || birdRect.intersects(pipe.bottomRect) {
                endGame()
            }
        }
        
        // Check scoring (when bird passes the center of a pipe)
        // Score when bird.x passes pipe.x + pipe.width/2 (the vertical line in the center of pipes)
        for i in pipes.indices {
            let pipeCenterX = pipes[i].x + pipes[i].width/2
            // If bird passes pipe center line -> increment score
            if pipeCenterX < bird.x && !isPipeAlreadyScored(pipe: pipes[i]) {
                score += 1
            }
        }
    }
    
    func isPipeAlreadyScored(pipe: Pipe) -> Bool {
        // A simple check: if pipe.x < bird.x and score counts pipes passed
        // This relies on the order pipes come in. A more robust way might store a state in the pipe.
        // For simplicity, count pipes out of view as scored:
        return pipe.x + pipe.width < bird.x
    }
    
    func endGame() {
        gameOver = true
        timer?.cancel()
        timer = nil
        isPlaying = false
    }
}

// MARK: - Views

struct FlappyBirdGameView: View {
    @StateObject var vm = GameViewModel()
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // Pipes
            ForEach(vm.pipes) { pipe in
                PipeView(pipe: pipe)
            }
            
            // Bird
            BirdView(y: vm.bird.y)
            
            // Score
            Text("\(vm.score)")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .position(x: UIScreen.main.bounds.width / 2, y: 100)
            
            // Game Over Prompt
            if vm.gameOver {
                VStack {
                    Text("Game Over")
                        .font(.largeTitle)
                        .bold()
                    Text("Tap to Restart")
                        .font(.headline)
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
            }
        }
        .ignoresSafeArea()
        .onTapGesture {
            vm.flap()
        }
    }
}

// MARK: - Subviews

struct BirdView: View {
    let y: CGFloat
    
    var body: some View {
        Image(systemName: "bird.fill")
            .resizable()
            .foregroundColor(.yellow)
            .frame(width: 40, height: 40)
            .position(x: 100, y: y)
    }
}

struct PipeView: View {
    let pipe: Pipe
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.green)
                .frame(width: pipe.width, height: pipe.topRect.height)
                .position(x: pipe.topRect.midX, y: pipe.topRect.midY)
            
            Rectangle()
                .fill(Color.green)
                .frame(width: pipe.width, height: pipe.bottomRect.height)
                .position(x: pipe.bottomRect.midX, y: pipe.bottomRect.midY)
        }
    }
}

// MARK: - Preview

#Preview {
    FlappyBirdGameView()
}
