import UIKit
import SpriteKit
import GameKit

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)

            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController {

    var tileSource : Tile?
    var tileDest : Tile?

    @IBOutlet weak var menuButton: UIButton!

    @IBOutlet weak var nextUnitButton: UIButton!
    @IBOutlet weak var nextVillageButton: UIButton!

    @IBOutlet weak var attackButton: UIButton!
    @IBOutlet weak var buildButton: UIButton!
    @IBOutlet weak var combineButton: UIButton!
    @IBOutlet weak var moveButton: UIButton!
    @IBOutlet weak var recruitButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!

    @IBOutlet weak var peasantButton: UIButton!
    @IBOutlet weak var infantryButton: UIButton!
    @IBOutlet weak var soldierButton: UIButton!
    @IBOutlet weak var knightButton: UIButton!
    @IBOutlet weak var canonButton: UIButton!
    @IBOutlet weak var upgradeUnitContainer: UIVisualEffectView!

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var validateButton: UIButton!

    @IBOutlet weak var roadButton: UIButton!
    @IBOutlet weak var towerButton: UIButton!
    @IBOutlet weak var meadowButton: UIButton!
    @IBOutlet weak var upgradeStructureContainer: UIVisualEffectView!

    @IBOutlet weak var endTurnButton: UIButton!

    // MARK: Info Panel Views

    @IBOutlet weak var regionVillage: UIImageView!
    @IBOutlet weak var regionGold: UILabel!
    @IBOutlet weak var regionWood: UILabel!
    @IBOutlet weak var regionHP: UILabel!
    @IBOutlet weak var regionState: UILabel!
    @IBOutlet weak var characterImage: UIImageView!
    @IBOutlet weak var characterName: UILabel!
    @IBOutlet weak var characterWage: UILabel!
    @IBOutlet weak var characterState: UILabel!

    @IBOutlet weak var turnLabel: UILabel!
    @IBOutlet weak var playerGoldWoodLabel: UILabel!

    // MARK - Info Panel

    func updateInfoPanel(tile: Tile?) {
        self.updateTurnLabel()
        // Update player gold/wood
        let goldText = "Gold: " + String((GameEngine.Instance.game?.localPlayer.gold)!)
        let woodText = "Wood: " + String((GameEngine.Instance.game?.localPlayer.wood)!)
        self.playerGoldWoodLabel.text =  goldText + "   " + woodText

        showNeutralInfo(tile)
        if let t = tile {
            if let village = t.owner {
                showVillageInfo(village)

                if let unit = t.unit { showUnitInfo(unit) }
            } else { showNeutralInfo(tile) }
        }
    }

    func showNeutralInfo(tile: Tile?) {
        if let t = tile {
            self.regionVillage.image = (t.land == Constants.Types.Land.Grass) ? nil : (UIImage(named: t.land.name()))
        } else { self.regionVillage.image = nil }
        self.regionVillage.backgroundColor = Utilities.Colors.colorForLandType(tile?.land ?? Constants.Types.Land.Grass, alpha: 1 )
        self.regionGold.text = ""
        self.regionWood.text = ""
        self.regionHP.text = ""
        self.regionState.text = ""
        self.characterImage.image = nil
        self.characterName.text = ""
        self.characterWage.text = ""
        self.characterState.text = ""
    }

    func showVillageInfo(village: Village) {
        self.regionVillage.image = UIImage(named: village.type.name())
        self.regionGold.text = "Gold: " + String(village.gold)
        self.regionWood.text = "Wood: " + String(village.wood)
        self.regionHP.text =  "HP: " + String(village.health)
        self.regionState.text = village.state.name()
    }

    func showUnitInfo(unit: Unit) {
        self.characterImage.image = UIImage(named: unit.type.name())
        self.characterName.text = unit.type.name().capitalizedString
        self.characterWage.text = "Wage: " + String(unit.type.wage())
        self.characterState.text = unit.currentAction.name()
    }
    
    func removeUnitInfo() { }

    // MARK: - Turn label update

    func updateTurnLabel() {
        self.turnLabel.text = GameEngine.Instance.game?.nameOfActivePlayer
    }

    // MARK: - Initializers

    var state : Constants.UI.State = .NothingPressed

    func showGamePlayScene() {
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.view as SKView
            skView.showsFPS = true
            //            skView.showsNodeCount = true
            //            skView.showsDrawCount = true

            self.hideActionButtons()

            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true

            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill

            skView.presentScene(scene)

            GameEngine.Instance.scene = scene
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.showNeutralInfo(nil)
        self.hideUnitSelection()

        validateButton.hidden = true
        cancelButton.hidden = true

        // Set MatchHelper's view controller
        MatchHelper.sharedInstance().vc = self

        self.showGamePlayScene()
    }

    // MARK: - Button Handlers

    @IBAction func nextUnitButtonTapped(sender: AnyObject) {
        if let tile = GameEngine.Instance.getNextAvailableUnit() {
            GameEngine.Instance.map?.centerAround(tile)
        }
    }

    @IBAction func nextVillageButtonTapped(sender: AnyObject) {
        if let tile = GameEngine.Instance.getNextAvailableVillage() {
            GameEngine.Instance.map?.centerAround(tile)
        }
    }

    @IBAction func attackButtonTapped(sender: AnyObject) {
        self.betweenPresses()
        self.state = .AttackPressed
        self.tileSource = GameEngine.Instance.map?.selected
        GameEngine.Instance.map?.resetColor()

        self.hideButton(attackButton)
        let seed = GameEngine.Instance.map?.selected
        if let tiles = GameEngine.Instance.map?.getAttackableRegion(seed!) {
            for t in tiles {
                t.lighten = true
            }
        }
        GameEngine.Instance.map?.draw()
    }

    @IBAction func buildButtonTapped(sender: AnyObject) {
        self.betweenPresses()
        if let tile = GameEngine.Instance.map?.selected {
            if tile.village != nil {
                self.towerButton.enabled = true
                self.roadButton.enabled = false
                self.meadowButton.enabled = false
            }
            else if tile.unit != nil {
                self.towerButton.enabled = false
                self.roadButton.enabled = true
                self.meadowButton.enabled = true
            }
        }

        self.hideButton(validateButton)
        self.upgradeStructureContainer.hidden = false

        self.tileSource = GameEngine.Instance.map?.selected
    }

    @IBAction func towerButtonTapped(sender: AnyObject) {
        self.state = .BuildTowerPressed

        GameEngine.Instance.map?.resetColor()
        if let tiles = tileSource?.owner.controlledTiles {
            for t in tiles {
                if t.isBuildable() {
                    t.lighten = true
                }
            }
        }
        self.doneWithBuild()
    }
    @IBAction func roadButtonTapped(sender: AnyObject) {
        self.state = .BuildRoadPressed

        GameEngine.Instance.map?.resetColor()
        if let tiles = GameEngine.Instance.map?.getBuildableRegion(tileSource!) {
            for t in tiles {
                t.lighten = true
            }
        }
        self.doneWithBuild()
    }
    @IBAction func meadowButtonTapped(sender: AnyObject) {
        self.state = .BuildMeadowPressed

        GameEngine.Instance.map?.resetColor()
        if let tiles = GameEngine.Instance.map?.getBuildableRegion(tileSource!) {
            for t in tiles {
                t.lighten = true
            }
        }
        self.doneWithBuild()
    }

    func doneWithBuild() {
        self.betweenPresses()
        self.upgradeStructureContainer.hidden = true
        GameEngine.Instance.updateInfoPanel()
        GameEngine.Instance.map?.draw()
    }

    @IBAction func moveButtonTapped(sender: AnyObject) {
        self.betweenPresses()
        self.state = .MovePressed
        if !(GameEngine.Instance.game?.localIsCurrentPlayer)! { return }
        GameEngine.Instance.map?.resetColor()

        self.tileSource = GameEngine.Instance.map?.selected

        if let unit = (tileSource)!.unit {
            if (tileSource)!.owner.player === GameEngine.Instance.game?.currentPlayer
                        && !unit.disabled {
                if let tiles = GameEngine.Instance.map?.getAccessibleRegion(tileSource!) {
                    for t in tiles {
                        t.lighten = true
                    }
                }

                self.validateButton.hidden = false
                self.cancelButton.hidden = false
            }
        }

        GameEngine.Instance.map?.draw()
    }

    @IBAction func combineButtonTapped(sender: AnyObject) {
        tileSource = GameEngine.Instance.map?.selected

        if !(tileSource?.isBelongsToLocal())! { return }
        if tileSource?.unit == nil { return }

        state = .CombinePressed
        betweenPresses()
    }

    @IBAction func endTurnButtonTapped(sender: AnyObject) {
        if !(GameEngine.Instance.game?.localIsCurrentPlayer)! { return }

        MatchHelper.sharedInstance().advanceMatchTurn()

        GameEngine.Instance.map?.resetColor()
        GameEngine.Instance.updateInfoPanel()
        GameEngine.Instance.map?.draw()
    }

    @IBAction func upgradeButtonTapped(sender: AnyObject) {
        if !(GameEngine.Instance.game?.localIsCurrentPlayer)! { return }

        self.tileSource = GameEngine.Instance.map?.selected
        if !(tileSource?.isBelongsToLocal())! { return }

        self.update(tileSource!)
        self.hideActionButtons()

        if tileSource?.village != nil {
            GameEngine.Instance.upgradeVillage(tileSource!)
        } else if tileSource?.unit != nil {
            self.showUpgradeOptions(tileSource!)
            self.state = .UpgradePressed
            self.showButton(cancelButton)
        }

        GameEngine.Instance.updateInfoPanel()
        GameEngine.Instance.map?.draw()
    }

    @IBAction func recruitButtonTapped(sender: AnyObject) {
        if !(GameEngine.Instance.game?.localIsCurrentPlayer)! { return }

        tileSource = GameEngine.Instance.map?.selected

        if tileSource?.owner == nil || !(tileSource?.isBelongsToLocal())! { return }

        self.state = .RecruitPressed
        self.showRecruitOptions(tileSource!)
        self.showButton(cancelButton)
    }

    @IBAction func peasantButtonTapped(sender: AnyObject) {
        if self.state == .RecruitPressed {
            GameEngine.Instance.recruitUnit(tileSource!, type: Constants.Types.Unit.Peasant)
        }
        self.doneWithUnit()
    }
    @IBAction func infantryButtonTapped(sender: AnyObject) {
        if self.state == .RecruitPressed {
            GameEngine.Instance.recruitUnit(tileSource!, type: Constants.Types.Unit.Infantry)
        } else if self.state == .UpgradePressed {
            GameEngine.Instance.upgradeUnit(tileSource!, newLevel: Constants.Types.Unit.Infantry)
        }
        self.doneWithUnit()
    }
    @IBAction func soldierButtonTapped(sender: AnyObject) {
        if self.state == .RecruitPressed {
            GameEngine.Instance.recruitUnit(tileSource!, type: Constants.Types.Unit.Soldier)
        } else if self.state == .UpgradePressed {
            GameEngine.Instance.upgradeUnit(tileSource!, newLevel: Constants.Types.Unit.Soldier)
        }
        self.doneWithUnit()
    }
    @IBAction func knightButtonTapped(sender: AnyObject) {
        if self.state == .RecruitPressed {
            GameEngine.Instance.recruitUnit(tileSource!, type: Constants.Types.Unit.Knight)
        } else if self.state == .UpgradePressed {
            GameEngine.Instance.upgradeUnit(tileSource!, newLevel: Constants.Types.Unit.Knight)
        }
        self.doneWithUnit()
    }
    @IBAction func canonButtonTapped(sender: AnyObject) {
        GameEngine.Instance.recruitUnit(tileSource!, type: Constants.Types.Unit.Canon)
        self.doneWithUnit()
    }

    func doneWithUnit() {
        self.hideUnitSelection()
        self.hideButton(cancelButton)
        self.state = .NothingPressed
        GameEngine.Instance.updateInfoPanel()
        GameEngine.Instance.map?.draw()
    }

    @IBAction func validateButtonTapped(sender: AnyObject) {
        GameEngine.Instance.map?.resetColor()
        let dest = GameEngine.Instance.map?.selected
        if self.state == .AttackPressed {
            GameEngine.Instance.attack(tileSource!, to: dest!)
        }else if self.state == .BuildRoadPressed {
            GameEngine.Instance.buildRoad(tileSource!, on: dest!)
        }
        else if self.state == .BuildMeadowPressed {
            GameEngine.Instance.startCultivating(tileSource!, on: dest!)
        }
        else if self.state == .BuildTowerPressed {
            GameEngine.Instance.buildTower(dest!)
        }
        else if self.state == .MovePressed {
            GameEngine.Instance.moveUnit(tileSource! , to: dest!)
        }
        else if self.state == .CombinePressed {
            if dest?.unit != nil {
                GameEngine.Instance.combineUnit(tileSource!, tileB: dest!)
            }
        }

        GameEngine.Instance.updateInfoPanel()
        validateButton.hidden = true
        cancelButton.hidden = true
        if self.state != .MovePressed && self.state != .BuildRoadPressed && self.state != .BuildMeadowPressed {
            GameEngine.Instance.map?.draw()
        }

        self.state = .NothingPressed
        self.update(dest!)
    }

    @IBAction func cancelButtonTapped(sender: AnyObject) {
        GameEngine.Instance.map?.resetColor()
        self.hideButton(validateButton)
        self.hideButton(cancelButton)
        GameEngine.Instance.map?.selected = tileSource!
        GameEngine.Instance.map?.draw()
        state = .NothingPressed

        self.update((GameEngine.Instance.map?.selected)!)
        self.hideUnitSelection()
        self.upgradeStructureContainer.hidden = true
    }

    func update(tile: Tile) {
        if self.state == .UpgradePressed || self.state == .RecruitPressed {
            self.doneWithUnit()
        }
        self.hideActionButtons()

        self.updateInfoPanel(tile)

        if !(GameEngine.Instance.game?.localIsCurrentPlayer)! {
            self.hidePlayerButtons()
        } else if !tile.isBelongsToLocal() {
            self.neutralSelected()  // neutral or other player
        } else if tile.village != nil {
            if !tile.owner.disaled {
                self.villageSelected(tile)
            } else {
                self.neutralSelected()
            }
        } else if let unit = tile.unit {
            if !unit.disabled {
                self.unitSelected(tile)
            } else {
                self.neutralSelected()
            }
        } else {
            self.neutralSelected()
        }
        self.updateInfoPanel(tile)
    }

    // buttons that are shown after certain selection
    func unitSelected(tile: Tile) {
        if self.state != .NothingPressed { return }

        if tile.unit?.type == Constants.Types.Unit.Peasant {
            self.showButton(buildButton)
        } else if tile.unit?.type == Constants.Types.Unit.Canon {
            self.showButton(attackButton)
        }
        if tile.unit?.type.rawValue < Constants.Types.Unit.Knight.rawValue {
            self.showButton(upgradeButton)
            self.showButton(combineButton)
        }
        self.showButton(moveButton)

        self.hideButton(recruitButton)
    }

    func villageSelected(tile: Tile) {
        if self.state != .NothingPressed { return }

        if tile.owner.type != Constants.Types.Village.Hovel {
            self.showButton(buildButton)
        }
        if tile.owner.type.rawValue < Constants.Types.Village.Castle.rawValue {
            self.showButton(upgradeButton)
        }
        self.showButton(recruitButton)

        self.hideButton(moveButton)
        self.hideButton(combineButton)
    }

    func neutralSelected() {
        self.hideButton(buildButton)
        self.hideButton(combineButton)
        self.hideButton(moveButton)
        self.hideButton(recruitButton)
        self.hideButton(upgradeButton)
    }

    func hidePlayerButtons() {
        self.hideActionButtons()

        self.hideButton(nextUnitButton)
        self.hideButton(nextVillageButton)
        self.hideButton(endTurnButton)
    }

    func betweenPresses() {
        self.showButton(cancelButton)
        self.showButton(validateButton)

        self.hideActionButtons()
    }

    func finishButtonPress() {
        self.hideButton(cancelButton)
        self.hideButton(validateButton)

        self.update((GameEngine.Instance.map?.selected)!)
    }

    func hideActionButtons() {
        self.hideButton(attackButton)
        self.hideButton(buildButton)
        self.hideButton(combineButton)
        self.hideButton(moveButton)
        self.hideButton(recruitButton)
        self.hideButton(upgradeButton)
    }

    func showUpgradeOptions(tile: Tile) {
        if let u = tile.unit {
        // show container
        self.upgradeUnitContainer.hidden = false

            switch u.type {
            case .Peasant:
            self.infantryButton.enabled = true
            self.soldierButton.enabled = true
            self.knightButton.enabled = true
            case .Infantry:
            self.soldierButton.enabled = true
            self.knightButton.enabled = true
            case .Soldier:
            self.knightButton.enabled = true
            default:
                println("wut")
            }
        }
    }

    func showRecruitOptions(tile: Tile) {
        if let v = tile.owner {
            self.upgradeUnitContainer.hidden = false

            self.peasantButton.enabled = true
            self.infantryButton.enabled = true

            if v.type.rawValue >= 1 {
            self.soldierButton.enabled = true
            }
            if v.type.rawValue >= 2 {
            self.knightButton.enabled = true
            }
            if v.type.rawValue >= 3 {
            self.canonButton.enabled = true
            }
        }
    }

    func hideUnitSelection() {
        self.peasantButton.enabled = false
        self.infantryButton.enabled = false
        self.soldierButton.enabled = false
        self.knightButton.enabled = false
        self.canonButton.enabled = false
        self.upgradeUnitContainer.hidden = true
    }

    // MARK: Visual helpers
    func showButton(button: UIButton) {
        button.hidden = false
        button.enabled = true
    }

    func hideButton(button: UIButton) {
        button.hidden = true
        button.enabled = false
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
