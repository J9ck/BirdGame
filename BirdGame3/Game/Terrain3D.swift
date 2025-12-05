//
//  Terrain3D.swift
//  BirdGame3
//
//  Procedural 3D terrain generation for open world
//

import SceneKit

// MARK: - Terrain 3D

/// Procedurally generated 3D terrain for the open world
class Terrain3D {
    
    // MARK: - Properties
    
    /// The main terrain node containing all terrain elements
    let terrainNode: SCNNode
    
    /// Size of the terrain in world units
    let terrainSize: Float = 2000
    
    /// Number of segments for terrain mesh
    let segments: Int = 50
    
    /// Current biome for coloring
    private var currentBiome: Biome = .plains
    
    /// Ground plane node
    private var groundNode: SCNNode?
    
    /// Tree nodes
    private var treeNodes: [SCNNode] = []
    
    /// Rock nodes
    private var rockNodes: [SCNNode] = []
    
    /// Water node (for beach/swamp)
    private var waterNode: SCNNode?
    
    // MARK: - Initialization
    
    init() {
        terrainNode = SCNNode()
        terrainNode.name = "terrain"
        
        setupGround()
        setupEnvironmentDetails()
    }
    
    // MARK: - Ground Setup
    
    private func setupGround() {
        // Create a large ground plane with height variation
        let groundGeometry = SCNPlane(width: CGFloat(terrainSize), height: CGFloat(terrainSize))
        groundGeometry.widthSegmentCount = segments
        groundGeometry.heightSegmentCount = segments
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.3, green: 0.5, blue: 0.2, alpha: 1.0)
        material.isDoubleSided = true
        groundGeometry.materials = [material]
        
        let ground = SCNNode(geometry: groundGeometry)
        ground.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        ground.position = SCNVector3(0, 0, 0)
        ground.name = "ground"
        
        groundNode = ground
        terrainNode.addChildNode(ground)
        
        // Add some height variation using child nodes
        addHeightVariation()
    }
    
    private func addHeightVariation() {
        // Create hills and valleys using sphere/box primitives
        let hillCount = 20
        
        for _ in 0..<hillCount {
            let hillSize = Float.random(in: 50...200)
            let hillHeight = Float.random(in: 10...50)
            
            let hillGeometry = SCNSphere(radius: CGFloat(hillSize))
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(red: 0.25, green: 0.45, blue: 0.18, alpha: 1.0)
            hillGeometry.materials = [material]
            
            let hillNode = SCNNode(geometry: hillGeometry)
            hillNode.position = SCNVector3(
                Float.random(in: -terrainSize/2...terrainSize/2),
                -hillSize + hillHeight,
                Float.random(in: -terrainSize/2...terrainSize/2)
            )
            hillNode.scale = SCNVector3(1, 0.3, 1) // Flatten to make hill-like
            hillNode.name = "hill"
            
            terrainNode.addChildNode(hillNode)
        }
    }
    
    // MARK: - Environment Details
    
    private func setupEnvironmentDetails() {
        addTrees()
        addRocks()
    }
    
    private func addTrees() {
        let treeCount = 100
        
        for _ in 0..<treeCount {
            let tree = createTree()
            tree.position = SCNVector3(
                Float.random(in: -terrainSize/2...terrainSize/2),
                0,
                Float.random(in: -terrainSize/2...terrainSize/2)
            )
            
            treeNodes.append(tree)
            terrainNode.addChildNode(tree)
        }
    }
    
    private func createTree() -> SCNNode {
        let treeNode = SCNNode()
        treeNode.name = "tree"
        
        // Trunk
        let trunkGeometry = SCNCylinder(radius: 0.5, height: 8)
        let trunkMaterial = SCNMaterial()
        trunkMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
        trunkGeometry.materials = [trunkMaterial]
        
        let trunkNode = SCNNode(geometry: trunkGeometry)
        trunkNode.position = SCNVector3(0, 4, 0)
        treeNode.addChildNode(trunkNode)
        
        // Foliage (cone shape)
        let foliageGeometry = SCNCone(topRadius: 0, bottomRadius: 4, height: 10)
        let foliageMaterial = SCNMaterial()
        foliageMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
        foliageGeometry.materials = [foliageMaterial]
        
        let foliageNode = SCNNode(geometry: foliageGeometry)
        foliageNode.position = SCNVector3(0, 12, 0)
        treeNode.addChildNode(foliageNode)
        
        // Random scale variation
        let scale = Float.random(in: 0.7...1.5)
        treeNode.scale = SCNVector3(scale, scale, scale)
        
        return treeNode
    }
    
    private func addRocks() {
        let rockCount = 50
        
        for _ in 0..<rockCount {
            let rock = createRock()
            rock.position = SCNVector3(
                Float.random(in: -terrainSize/2...terrainSize/2),
                Float.random(in: 0...2),
                Float.random(in: -terrainSize/2...terrainSize/2)
            )
            
            rockNodes.append(rock)
            terrainNode.addChildNode(rock)
        }
    }
    
    private func createRock() -> SCNNode {
        let rockGeometry = SCNSphere(radius: CGFloat(Float.random(in: 1...5)))
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        material.roughness.contents = 0.8
        rockGeometry.materials = [material]
        
        let rockNode = SCNNode(geometry: rockGeometry)
        rockNode.name = "rock"
        
        // Random deformation to make it look more natural
        rockNode.scale = SCNVector3(
            Float.random(in: 0.8...1.2),
            Float.random(in: 0.6...1.0),
            Float.random(in: 0.8...1.2)
        )
        
        return rockNode
    }
    
    // MARK: - Biome Updates
    
    /// Update terrain colors and features based on biome
    func updateBiomeColors(_ biome: Biome) {
        guard biome != currentBiome else { return }
        currentBiome = biome
        
        // Update ground color
        updateGroundForBiome(biome)
        
        // Update trees
        updateTreesForBiome(biome)
        
        // Update rocks
        updateRocksForBiome(biome)
        
        // Update hills
        updateHillsForBiome(biome)
        
        // Add/remove water for certain biomes
        updateWaterForBiome(biome)
    }
    
    private func updateGroundForBiome(_ biome: Biome) {
        guard let ground = groundNode,
              let material = ground.geometry?.firstMaterial else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        
        switch biome {
        case .forest:
            material.diffuse.contents = UIColor(red: 0.2, green: 0.4, blue: 0.15, alpha: 1.0)
        case .desert:
            material.diffuse.contents = UIColor(red: 0.85, green: 0.75, blue: 0.55, alpha: 1.0)
        case .mountain:
            material.diffuse.contents = UIColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        case .swamp:
            material.diffuse.contents = UIColor(red: 0.25, green: 0.35, blue: 0.2, alpha: 1.0)
        case .beach:
            material.diffuse.contents = UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0)
        case .tundra:
            material.diffuse.contents = UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0)
        case .jungle:
            material.diffuse.contents = UIColor(red: 0.15, green: 0.35, blue: 0.1, alpha: 1.0)
        case .plains:
            material.diffuse.contents = UIColor(red: 0.4, green: 0.55, blue: 0.25, alpha: 1.0)
        }
        
        SCNTransaction.commit()
    }
    
    private func updateTreesForBiome(_ biome: Biome) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        
        for tree in treeNodes {
            // Update foliage color
            if let foliageNode = tree.childNodes.last,
               let material = foliageNode.geometry?.firstMaterial {
                switch biome {
                case .forest:
                    material.diffuse.contents = UIColor(red: 0.15, green: 0.45, blue: 0.15, alpha: 1.0)
                    tree.isHidden = false
                case .desert:
                    tree.isHidden = Bool.random() // Few trees in desert
                    material.diffuse.contents = UIColor(red: 0.4, green: 0.35, blue: 0.2, alpha: 1.0)
                case .mountain:
                    material.diffuse.contents = UIColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 1.0)
                    tree.isHidden = false
                case .swamp:
                    material.diffuse.contents = UIColor(red: 0.2, green: 0.4, blue: 0.15, alpha: 1.0)
                    tree.isHidden = false
                case .beach:
                    // Palm tree colors
                    material.diffuse.contents = UIColor(red: 0.3, green: 0.5, blue: 0.2, alpha: 1.0)
                    tree.isHidden = Bool.random()
                case .tundra:
                    // Sparse, dark evergreens
                    material.diffuse.contents = UIColor(red: 0.1, green: 0.25, blue: 0.1, alpha: 1.0)
                    tree.isHidden = Bool.random()
                case .jungle:
                    material.diffuse.contents = UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
                    tree.isHidden = false
                case .plains:
                    material.diffuse.contents = UIColor(red: 0.2, green: 0.45, blue: 0.15, alpha: 1.0)
                    tree.isHidden = Bool.random()
                }
            }
        }
        
        SCNTransaction.commit()
    }
    
    private func updateRocksForBiome(_ biome: Biome) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        
        for rock in rockNodes {
            if let material = rock.geometry?.firstMaterial {
                switch biome {
                case .forest:
                    material.diffuse.contents = UIColor(red: 0.45, green: 0.45, blue: 0.4, alpha: 1.0)
                    rock.isHidden = Bool.random()
                case .desert:
                    material.diffuse.contents = UIColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0)
                    rock.isHidden = false
                case .mountain:
                    material.diffuse.contents = UIColor(red: 0.55, green: 0.55, blue: 0.6, alpha: 1.0)
                    rock.isHidden = false
                    rock.scale = SCNVector3(rock.scale.x * 1.5, rock.scale.y * 1.5, rock.scale.z * 1.5)
                case .swamp:
                    material.diffuse.contents = UIColor(red: 0.35, green: 0.35, blue: 0.3, alpha: 1.0)
                    rock.isHidden = Bool.random()
                case .beach:
                    material.diffuse.contents = UIColor(red: 0.8, green: 0.75, blue: 0.7, alpha: 1.0)
                    rock.isHidden = Bool.random()
                case .tundra:
                    material.diffuse.contents = UIColor(red: 0.7, green: 0.72, blue: 0.75, alpha: 1.0)
                    rock.isHidden = false
                case .jungle:
                    material.diffuse.contents = UIColor(red: 0.4, green: 0.4, blue: 0.35, alpha: 1.0)
                    rock.isHidden = Bool.random()
                case .plains:
                    material.diffuse.contents = UIColor(red: 0.5, green: 0.5, blue: 0.45, alpha: 1.0)
                    rock.isHidden = Bool.random()
                }
            }
        }
        
        SCNTransaction.commit()
    }
    
    private func updateHillsForBiome(_ biome: Biome) {
        terrainNode.enumerateChildNodes { node, _ in
            guard node.name == "hill",
                  let material = node.geometry?.firstMaterial else { return }
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            
            switch biome {
            case .forest:
                material.diffuse.contents = UIColor(red: 0.2, green: 0.4, blue: 0.15, alpha: 1.0)
            case .desert:
                material.diffuse.contents = UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0)
            case .mountain:
                material.diffuse.contents = UIColor(red: 0.55, green: 0.55, blue: 0.6, alpha: 1.0)
                node.scale = SCNVector3(1, 0.5, 1) // Taller hills for mountains
            case .swamp:
                material.diffuse.contents = UIColor(red: 0.25, green: 0.35, blue: 0.2, alpha: 1.0)
                node.scale = SCNVector3(1, 0.1, 1) // Flat swamp
            case .beach:
                material.diffuse.contents = UIColor(red: 0.85, green: 0.8, blue: 0.65, alpha: 1.0)
                node.scale = SCNVector3(1, 0.1, 1) // Flat beach
            case .tundra:
                material.diffuse.contents = UIColor(red: 0.9, green: 0.92, blue: 0.95, alpha: 1.0)
            case .jungle:
                material.diffuse.contents = UIColor(red: 0.15, green: 0.35, blue: 0.1, alpha: 1.0)
            case .plains:
                material.diffuse.contents = UIColor(red: 0.35, green: 0.5, blue: 0.2, alpha: 1.0)
                node.scale = SCNVector3(1, 0.15, 1) // Gentle rolling hills
            }
            
            SCNTransaction.commit()
        }
    }
    
    private func updateWaterForBiome(_ biome: Biome) {
        // Remove existing water
        waterNode?.removeFromParentNode()
        waterNode = nil
        
        // Add water for beach and swamp biomes
        if biome == .beach || biome == .swamp {
            let waterSize = terrainSize * 0.4
            let waterGeometry = SCNPlane(width: CGFloat(waterSize), height: CGFloat(waterSize))
            
            let waterMaterial = SCNMaterial()
            waterMaterial.diffuse.contents = biome == .beach ?
                UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.7) :
                UIColor(red: 0.2, green: 0.35, blue: 0.25, alpha: 0.8)
            waterMaterial.transparency = 0.7
            waterMaterial.isDoubleSided = true
            waterGeometry.materials = [waterMaterial]
            
            let water = SCNNode(geometry: waterGeometry)
            water.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            water.position = SCNVector3(
                Float.random(in: -200...200),
                1,
                Float.random(in: -200...200)
            )
            water.name = "water"
            
            waterNode = water
            terrainNode.addChildNode(water)
            
            // Animate water with gentle wave
            let waveUp = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 2)
            let waveDown = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 2)
            waveUp.timingMode = .easeInEaseOut
            waveDown.timingMode = .easeInEaseOut
            let waveSequence = SCNAction.sequence([waveUp, waveDown])
            water.runAction(SCNAction.repeatForever(waveSequence))
        }
    }
    
    // MARK: - Terrain Queries
    
    /// Get the height at a specific world position
    func getHeightAt(x: Float, z: Float) -> Float {
        // Simple height calculation based on distance from origin
        // In a real implementation, this would use noise functions or heightmap data
        let distance = sqrt(x * x + z * z)
        let baseHeight: Float = 0
        
        // Add some variation
        let variation = sin(x * 0.01) * cos(z * 0.01) * 10
        
        return baseHeight + variation
    }
    
    /// Check if a position is in water
    func isInWater(x: Float, z: Float) -> Bool {
        guard let water = waterNode else { return false }
        
        let waterPos = water.position
        let waterSize = terrainSize * 0.4 / 2
        
        return abs(x - waterPos.x) < waterSize && abs(z - waterPos.z) < waterSize
    }
}
