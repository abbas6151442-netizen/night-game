import UIKit
import SceneKit
import AVFoundation

let S = UserDefaults.standard
var lang: String { get { S.string(forKey: "lang") ?? "" } set { S.set(newValue, forKey: "lang") } }
var vol: Float { get { S.object(forKey: "vol") as? Float ?? 0.6 } set { S.set(newValue, forKey: "vol") } }
var sens: Float { get { S.object(forKey: "sens") as? Float ?? 1 } set { S.set(newValue, forKey: "sens") } }
var fxOn: Bool { get { S.object(forKey: "fx") as? Bool ?? true } set { S.set(newValue, forKey: "fx") } }
let RED = UIColor(red: 0.75, green: 0.12, blue: 0.1, alpha: 1)

let TXT: [String: (String, String)] = [
    "title": ("THE DREAM", "الحلم"), "play": ("PLAY", "ابدأ"), "settings": ("SETTINGS", "الإعدادات"),
    "back": ("BACK", "رجوع"), "lang": ("LANGUAGE: ENGLISH", "اللغة: العربية"), "vol": ("MUSIC", "الموسيقى"),
    "sens": ("LOOK SPEED", "سرعة النظر"), "fx": ("EFFECTS", "التأثيرات"),
    "n1": ("NIGHT 1", "الليلة الأولى"), "n2": ("NIGHT 2", "الليلة الثانية"),
    "wake": ("He wakes up.\nThe same wound is on his leg.", "يستيقظ...\nويجد الجرح نفسه في ساقه."),
    "end": ("END OF PART 1", "نهاية الجزء الأول")
]
func T(_ k: String) -> String { let v = TXT[k]!; return lang == "ar" ? v.1 : v.0 }

func img(_ n: String, _ e: String) -> UIImage? { Bundle.main.path(forResource: n, ofType: e).flatMap { UIImage(contentsOfFile: $0) } }
final class Snd {
    static var cache: [String: AVAudioPlayer] = [:]
    @discardableResult static func play(_ n: String, _ v: Float = 1, loop: Bool = false) -> AVAudioPlayer? {
        if cache[n] == nil, let u = Bundle.main.url(forResource: n, withExtension: "wav") { cache[n] = try? AVAudioPlayer(contentsOf: u) }
        let p = cache[n]
        p?.volume = v * vol; p?.numberOfLoops = loop ? -1 : 0; p?.currentTime = 0; p?.play()
        return p
    }
}
func mat(_ c: UIColor, lit: Bool = true) -> SCNMaterial {
    let m = SCNMaterial(); m.diffuse.contents = c; m.isDoubleSided = true
    m.lightingModel = lit ? .lambert : .constant
    return m
}
func col(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> SCNMaterial { mat(UIColor(red: r, green: g, blue: b, alpha: 1)) }
func tmat(_ n: String, _ e: String, _ rx: Float, _ ry: Float) -> SCNMaterial {
    let m = SCNMaterial()
    m.diffuse.contents = img(n, e) ?? UIColor.gray
    m.diffuse.wrapS = .repeat; m.diffuse.wrapT = .repeat
    m.diffuse.magnificationFilter = .nearest; m.diffuse.minificationFilter = .nearest; m.diffuse.mipFilter = .none
    m.diffuse.contentsTransform = SCNMatrix4MakeScale(rx, ry, 1)
    m.isDoubleSided = true; m.lightingModel = .lambert
    return m
}
func btn(_ t: String, _ target: Any?, _ a: Selector) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(t, for: .normal); b.setTitleColor(UIColor(white: 0.9, alpha: 1), for: .normal)
    b.titleLabel?.font = UIFont(name: "Courier-Bold", size: 20) ?? .boldSystemFont(ofSize: 20)
    b.layer.borderColor = RED.cgColor; b.layer.borderWidth = 1.5
    b.addTarget(target, action: a, for: .touchUpInside)
    b.widthAnchor.constraint(equalToConstant: 260).isActive = true
    b.heightAnchor.constraint(equalToConstant: 40).isActive = true
    return b
}
@discardableResult func blk(_ p: SCNNode, _ w: CGFloat, _ h: CGFloat, _ l: CGFloat, _ x: Float, _ y: Float, _ z: Float, _ m: SCNMaterial) -> SCNNode {
    let n = SCNNode(geometry: SCNBox(width: w, height: h, length: l, chamferRadius: 0.01))
    n.geometry?.firstMaterial = m; n.position = SCNVector3(x, y, z); p.addChildNode(n); return n
}
// room: wood floor, wallpaper walls, front wall has a door opening
func hall(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat, floor: String, wall: String) -> SCNNode {
    let n = SCNNode()
    func p(_ pw: CGFloat, _ ph: CGFloat, _ pos: SCNVector3, _ ang: SCNVector3, _ t: String) {
        let k = SCNNode(geometry: SCNPlane(width: pw, height: ph))
        k.geometry?.firstMaterial = tmat(t, "jpg", Float(pw), Float(ph)); k.position = pos; k.eulerAngles = ang; n.addChildNode(k)
    }
    let H = Float(h), W = Float(w), L = Float(l), pi = Float.pi
    p(w, l, SCNVector3(0, 0, 0), SCNVector3(-pi / 2, 0, 0), floor)
    p(w, l, SCNVector3(0, H, 0), SCNVector3(pi / 2, 0, 0), wall)
    p(w, h, SCNVector3(0, H / 2, -L / 2), SCNVector3(0, 0, 0), wall)
    p(l, h, SCNVector3(-W / 2, H / 2, 0), SCNVector3(0, pi / 2, 0), wall)
    p(l, h, SCNVector3(W / 2, H / 2, 0), SCNVector3(0, -pi / 2, 0), wall)
    p(3.7, h, SCNVector3(-1.15, H / 2, L / 2), SCNVector3(0, pi, 0), wall)
    p(1.3, h, SCNVector3(2.35, H / 2, L / 2), SCNVector3(0, pi, 0), wall)
    p(1.0, 0.9, SCNVector3(1.2, 2.55, L / 2), SCNVector3(0, pi, 0), wall)
    return n
}
// round tunnel, normals point inward
func tube(_ r: Float, _ len: Float, _ seg: Int, _ tu: Float, _ tv: Float) -> SCNGeometry {
    var v = [SCNVector3](), n = [SCNVector3](), t = [CGPoint](), idx = [Int32]()
    for i in 0...seg {
        let a = Float(i) / Float(seg) * 2 * Float.pi
        for z in [Float(-len / 2), Float(len / 2)] {
            v.append(SCNVector3(cos(a) * r, sin(a) * r, z)); n.append(SCNVector3(-cos(a), -sin(a), 0))
            t.append(CGPoint(x: CGFloat(Float(i) / Float(seg) * tu), y: CGFloat((z + len / 2) / len * tv)))
        }
    }
    for i in 0..<seg { let k = Int32(i * 2); idx += [k, k + 2, k + 1, k + 1, k + 2, k + 3] }
    return SCNGeometry(sources: [SCNGeometrySource(vertices: v), SCNGeometrySource(normals: n), SCNGeometrySource(textureCoordinates: t)],
                       elements: [SCNGeometryElement(indices: idx, primitiveType: .triangles)])
}
func addLight(_ t: SCNLight.LightType, _ i: CGFloat, _ c: UIColor, to p: SCNNode, at pos: SCNVector3, _ d: CGFloat = 0) {
    let l = SCNLight(); l.type = t; l.intensity = i; l.color = c
    if d > 0 { l.attenuationEndDistance = d }
    let n = SCNNode(); n.light = l; n.position = pos; p.addChildNode(n)
}

final class GameView: UIView {
    var night = 0   // 0 = going to bed, 1 = dream, 2 = tunnel
    var onExit: (() -> Void)?
    let sv = SCNView(), rig = SCNNode(), cam = SCNNode()
    var yaw: Float = 0, pitch: Float = 0, bob: Float = 0, dist: Float = 0, shake: Float = 0, ft: Float = 0, tt: Float = 0, introT: Float = 0, mdir: Float = 1
    var bx: Float = 3, bz: Float = 3
    var state = 0, alive = true, introDone = false
    var jv = CGPoint.zero, moveStart = CGPoint.zero, lastLook = CGPoint.zero
    var moveT: UITouch?, lookT: UITouch?
    var knife: SCNNode?, monster: SCNNode?, door: SCNNode?
    var water: SCNMaterial?
    var link: CADisplayLink?
    let ui = UIView(), ring = UIView(), dot = UIView(), cover = UIView(), label = UILabel()
    let grain = UIView(), tint = CAGradientLayer(), pic = UIImageView()
    var bgm: AVAudioPlayer?, chase: AVAudioPlayer?
    var near: Float = 0
    var stepT: Float = 0
    var tex: [UIImage] = []
    let KF: [[Float]] = [[0, 1.2, 1.6, 4.4, 0, 0], [1.8, 1.2, 1.6, 4.4, 0, 0], [4.2, 1.2, 1.6, 0.8, 0, 0],
                         [6.2, -1.2, 1.6, -1.8, 1.57, -0.35], [8.2, -2.2, 0.95, -1.8, 1.57, 1.25]]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true; backgroundColor = .black; clipsToBounds = true
        sv.isUserInteractionEnabled = false; sv.antialiasingMode = .none; sv.preferredFramesPerSecond = 30
        sv.isPlaying = true; sv.backgroundColor = .black
        addSubview(sv)
        let c = SCNCamera(); c.zNear = 0.05; c.zFar = 200; c.fieldOfView = 75
        c.wantsHDR = true; c.wantsExposureAdaptation = false
        cam.camera = c; rig.addChildNode(cam)
        tex = [img("entity", "png")].compactMap { $0 }
        if tex.isEmpty {
            tex = [UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { UIColor.green.setFill(); $0.fill(CGRect(x: 0, y: 0, width: 8, height: 8)) }]
        }
        // chunky moving film grain over the whole picture
        ui.isUserInteractionEnabled = false; ui.clipsToBounds = true; addSubview(ui)
        if let g = img("noise", "png")?.cgImage { grain.layer.contents = g }
        grain.layer.magnificationFilter = .nearest; grain.alpha = 0.3; ui.addSubview(grain)
        // rich color: warm on top, blue at the bottom
        tint.colors = [UIColor(red: 0.95, green: 0.5, blue: 0.12, alpha: 1).cgColor, UIColor(red: 0.05, green: 0.2, blue: 0.75, alpha: 1).cgColor]
        tint.startPoint = CGPoint(x: 0.5, y: 0); tint.endPoint = CGPoint(x: 0.5, y: 1)
        tint.opacity = 0.45; tint.compositingFilter = "softLightBlendMode"
        ui.layer.insertSublayer(tint, at: 0)
        for (v, s) in [(ring, 100.0), (dot, 44.0)] {
            v.bounds = CGRect(x: 0, y: 0, width: s, height: s); v.layer.cornerRadius = CGFloat(s / 2)
            v.layer.borderColor = UIColor(white: 1, alpha: 0.3).cgColor; v.layer.borderWidth = 2
            v.alpha = 0; v.isUserInteractionEnabled = false; addSubview(v)
        }
        cover.isUserInteractionEnabled = false
        label.font = UIFont(name: "Courier-Bold", size: 26) ?? .boldSystemFont(ofSize: 26)
        label.textColor = .white; label.textAlignment = .center; label.numberOfLines = 0; label.alpha = 0
        pic.image = img("eye", "jpg"); pic.contentMode = .scaleAspectFill; pic.clipsToBounds = true; pic.backgroundColor = .black; pic.alpha = 0
        pic.layer.magnificationFilter = .nearest
        [cover, pic, label].forEach { addSubview($0) }
        let x = UIButton(type: .system); x.setTitle("✕", for: .normal); x.setTitleColor(UIColor(white: 1, alpha: 0.5), for: .normal)
        x.frame = CGRect(x: 10, y: 8, width: 44, height: 44); x.addTarget(self, action: #selector(quit), for: .touchUpInside)
        addSubview(x)
    }
    required init?(coder: NSCoder) { fatalError() }

    // the game is shown in a centered 5:4 box with chunky low-res pixels
    override func layoutSubviews() {
        super.layoutSubviews()
        let h = min(bounds.height, bounds.width / 1.25), w = h * 1.25
        let q = CGRect(x: (bounds.width - w) / 2, y: (bounds.height - h) / 2, width: w, height: h)
        sv.frame = q; ui.frame = q; cover.frame = q; pic.frame = q; label.frame = q.insetBy(dx: 16, dy: 0)
        grain.frame = CGRect(x: -20, y: -20, width: w + 40, height: h + 40)
        sv.contentScaleFactor = fxOn ? 480 / w : UIScreen.main.scale
        CATransaction.begin(); CATransaction.setDisableActions(true); tint.frame = ui.bounds; CATransaction.commit()
        sv.layer.magnificationFilter = .nearest
    }

    func applyFx() {
        let c = cam.camera!, k: CGFloat = fxOn ? 1 : 0
        c.saturation = 1 + 0.25 * k; c.grainIntensity = 0.25 * k; c.colorFringeStrength = 0
        c.vignettingIntensity = 0.35 * k; c.vignettingPower = 1
        ui.isHidden = !fxOn
    }
    func after(_ s: Double, _ f: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + s) { [weak self] in if self?.alive == true { f() } }
    }
    func card(_ t: String) { label.text = t; label.alpha = 1 }
    func hud(_ name: String, _ h: CGFloat, _ x: Float, _ y: Float, _ rot: Float, _ order: Int) -> SCNNode {
        let im = img(name, "png"), s = im?.size ?? CGSize(width: 1, height: 1)
        let m = SCNMaterial(); m.lightingModel = .constant; m.isDoubleSided = true; m.diffuse.contents = im ?? UIColor.gray
        m.diffuse.magnificationFilter = .nearest; m.diffuse.minificationFilter = .nearest
        m.readsFromDepthBuffer = false; m.writesToDepthBuffer = false
        let n = SCNNode(geometry: SCNPlane(width: h * s.width / s.height, height: h))
        n.geometry?.firstMaterial = m; n.position = SCNVector3(x, y, -0.5); n.eulerAngles = SCNVector3(0, 0, rot); n.renderingOrder = order
        cam.addChildNode(n); return n
    }

    func start() {
        link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link?.preferredFramesPerSecond = 30; link?.add(to: .main, forMode: .common)
        begin()
    }
    @objc func quit() {
        guard alive else { return }
        alive = false; bgm?.stop(); chase?.stop(); link?.invalidate(); link = nil; removeFromSuperview(); onExit?()
    }

    func begin() {
        state = 0; dist = 0; yaw = 0; pitch = 0; bob = 0; shake = 0; monster = nil; jv = .zero; introT = 0; introDone = false; water = nil; chase?.stop(); chase = nil; near = 0
        cover.backgroundColor = .black; cover.alpha = 1; pic.alpha = 0; label.alpha = 0; label.textColor = .white
        cam.childNodes.forEach { $0.removeFromParentNode() }
        let sc = SCNScene(); sc.rootNode.addChildNode(rig); sv.scene = sc; sv.pointOfView = cam
        sc.fogColor = night == 2 ? UIColor.black : UIColor(red: 0.16, green: 0.17, blue: 0.26, alpha: 1)
        rig.position = SCNVector3(0, 1.6, 0)
        if night == 2 { build2(sc) } else { build1(sc) }
        applyFx()
        bgm?.stop(); bgm = Snd.play(night == 2 ? "tunnel" : "amb", night == 2 ? 0.9 : 0.5, loop: true)
        if night == 0 {
            after(0.8) { _ = Snd.play("creak", 0.8) }
            state = 3; UIView.animate(withDuration: 1) { self.cover.alpha = 0 }
        } else {
            card(T(night == 1 ? "n1" : "n2"))
            after(2.2) { self.label.alpha = 0; UIView.animate(withDuration: 0.6) { self.cover.alpha = 0 }; self.state = 1 }
        }
    }

    // bedroom: real (night 0) or dream version (night 1)
    func build1(_ sc: SCNScene) {
        let dream = night == 1, R = sc.rootNode
        sc.fogStartDistance = 3; sc.fogEndDistance = dream ? 11 : 20; bx = 2.9; bz = 2.9
        R.addChildNode(hall(6, 3, 6, floor: "wood", wall: "paper"))
        let dr = SCNNode(); dr.position = SCNVector3(0.7, 0, 2.99); R.addChildNode(dr); door = dr
        blk(dr, 1, 2.1, 0.05, 0.5, 1.05, 0, tmat("wood", "jpg", 1, 2))
        let wood = tmat("wood", "jpg", 1, 1), white = col(0.8, 0.8, 0.82)
        blk(R, 1.5, 0.35, 2.3, -2.2, 0.18, -1.8, wood)
        blk(R, 1.4, 0.2, 2.2, -2.2, 0.45, -1.8, white)
        blk(R, 1.4, 0.12, 1.4, -2.2, 0.6, -1.4, col(0.45, 0.12, 0.15))
        blk(R, 0.6, 0.14, 0.35, -2.2, 0.62, -2.65, white)
        blk(R, 1.6, 0.9, 0.08, -2.2, 0.75, -2.95, wood)
        blk(R, 0.5, 0.5, 0.45, -1.1, 0.25, -2.7, wood)
        blk(R, 0.16, 0.25, 0.16, -1.1, 0.62, -2.7, mat(UIColor(red: 1, green: 0.8, blue: 0.5, alpha: 1), lit: false))
        blk(R, 1.2, 2.2, 0.6, 2.3, 1.1, -2.65, tmat("wood", "jpg", 1, 2))
        blk(R, 1.3, 0.05, 0.6, 2.2, 0.75, -0.5, wood)
        blk(R, 0.05, 0.75, 0.55, 1.6, 0.375, -0.5, wood); blk(R, 0.05, 0.75, 0.55, 2.8, 0.375, -0.5, wood)
        blk(R, 0.45, 0.05, 0.45, 2.2, 0.45, 0.2, wood); blk(R, 0.45, 0.5, 0.05, 2.2, 0.72, 0.42, wood); blk(R, 0.06, 0.45, 0.06, 2.2, 0.22, 0.2, wood)
        blk(R, 2.4, 0.02, 1.8, 0, 0.011, 0.2, col(0.35, 0.1, 0.12))
        blk(R, 0.04, 1.2, 1.0, 2.96, 1.7, 0.8, mat(UIColor(red: 0.25, green: 0.35, blue: 0.7, alpha: 1), lit: false))
        blk(R, 0.6, 0.45, 0.04, 0.4, 1.8, -2.97, wood); blk(R, 0.5, 0.35, 0.05, 0.4, 1.8, -2.96, col(0.2, 0.3, 0.25))
        blk(R, 0.45, 0.6, 0.04, 1.3, 1.7, -2.97, wood); blk(R, 0.35, 0.5, 0.05, 1.3, 1.7, -2.96, col(0.3, 0.25, 0.2))
        if dream {
            addLight(.ambient, 150, UIColor(red: 0.55, green: 0.4, blue: 0.7, alpha: 1), to: R, at: SCNVector3Zero)
            addLight(.omni, 350, UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1), to: R, at: SCNVector3(0, 2.6, 0))
            rig.position = SCNVector3(0, 1.6, 0.8)
            knife = hud("knife", 0.46, 0.2, -0.1, 0.1, 100)
            _ = hud("hand", 0.3, 0.22, -0.3, 0, 101)
        } else {
            addLight(.ambient, 260, UIColor(red: 0.6, green: 0.65, blue: 0.9, alpha: 1), to: R, at: SCNVector3Zero)
            addLight(.omni, 700, UIColor(red: 1, green: 0.8, blue: 0.55, alpha: 1), to: R, at: SCNVector3(-1.1, 1.1, -2.6), 7)
            addLight(.omni, 300, UIColor(red: 0.5, green: 0.6, blue: 1, alpha: 1), to: R, at: SCNVector3(2.4, 1.7, 0.8), 6)
            rig.position = SCNVector3(1.2, 1.6, 4.4)
        }
    }

    // round dark tunnel with drawings on the wall and water on the floor; the end light only shows when close
    func build2(_ sc: SCNScene) {
        sc.fogStartDistance = 2; sc.fogEndDistance = 28; bx = 0.8; bz = 58.5
        let t = SCNNode(geometry: tube(1.6, 120, 28, 1, 25.5))
        t.geometry?.firstMaterial = tmat("wall", "jpg", 1, 1); t.position = SCNVector3(0, 1.6, 0); sc.rootNode.addChildNode(t)
        let w = SCNNode(geometry: SCNPlane(width: 1.3, height: 120))
        let wm = tmat("water", "jpg", 1, 100); wm.transparency = 0.9; w.geometry?.firstMaterial = wm; water = wm
        w.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0); w.position = SCNVector3(0, 0.14, 0); sc.rootNode.addChildNode(w)
        for s: Float in [-1, 1] {
            let g = SCNPlane(width: 3.2, height: 3.2); g.cornerRadius = 1.6
            let e = SCNNode(geometry: g); e.geometry?.firstMaterial = mat(.white, lit: false); e.position = SCNVector3(0, 1.6, s * 59.9)
            sc.rootNode.addChildNode(e)
        }
        addLight(.ambient, 110, .white, to: sc.rootNode, at: SCNVector3Zero)
        addLight(.spot, 2600, UIColor(red: 1, green: 0.93, blue: 0.78, alpha: 1), to: cam, at: SCNVector3Zero)
        if let l = cam.childNodes.last?.light { l.spotInnerAngle = 15; l.spotOuterAngle = 55; l.attenuationEndDistance = 28 }
    }

    // the white entity runs after you from behind; its strange sound grows as it gets close
    func spawn() {
        let h: CGFloat = 1.8, w = h * tex[0].size.width / tex[0].size.height
        let m = SCNMaterial(); m.lightingModel = .constant; m.isDoubleSided = true; m.diffuse.contents = tex[0]
        m.diffuse.magnificationFilter = .nearest; m.diffuse.minificationFilter = .nearest
        let g = SCNPlane(width: w, height: h); g.firstMaterial = m
        let n = SCNNode(geometry: g)
        mdir = rig.position.z > 0 ? 1 : -1
        n.position = SCNVector3(0, 0.9, rig.position.z - mdir * 14)
        let bc = SCNBillboardConstraint(); bc.freeAxes = .Y; n.constraints = [bc]
        sv.scene?.rootNode.addChildNode(n); monster = n
        chase = Snd.play("chase", 0.1, loop: true)
    }
    func lead(_ m: SCNNode, _ dt: Float) {
        ft += dt
        let p = rig.position
        let z = m.position.z + mdir * 3.5 * dt
        m.position = SCNVector3(p.x * 0.5, 0.9 + abs(sin(ft * 12)) * 0.1, z)
        let gap = (p.z - z) * mdir
        near = max(0, min(1, 1 - gap / 14))
        chase?.volume = vol * (0.1 + 0.9 * near)
        if gap < 1.2 { caught() }
    }
    func caught() {
        state = 2; near = 0; chase?.stop(); _ = Snd.play("sting", 1)
        cover.alpha = 1; label.alpha = 0
        after(1) { self.pic.alpha = 1 }
        after(3.2) { self.begin() }
    }

    func drop() {
        state = 2; shake = 0.05; _ = Snd.play("thud", 1)
        knife?.runAction(.group([.moveBy(x: 0, y: -0.5, z: 0.1, duration: 0.5), .rotateBy(x: 0, y: 0, z: 1.2, duration: 0.5)]))
        after(0.6) { UIView.animate(withDuration: 0.3) { self.cover.alpha = 1 } }
        after(1.4) { self.card(T("wake")); _ = Snd.play("sting", 0.7) }
        after(5.2) { self.night = 2; self.begin() }
    }
    func win() {
        state = 2; chase?.stop(); cover.backgroundColor = .white
        UIView.animate(withDuration: 1.5) { self.cover.alpha = 1 }
        after(1.6) { self.label.textColor = .black; self.card(T("end")) }
        after(5) { self.quit() }
    }

    // going to bed: open the door, walk in, lie down, sleep
    func intro(_ dt: Float) {
        introT += dt
        door?.eulerAngles = SCNVector3(0, 1.7 * min(1, max(0, introT - 0.8)), 0)
        var i = 0
        while i < KF.count - 2 && introT > KF[i + 1][0] { i += 1 }
        let a = KF[i], b = KF[i + 1]
        var u = max(0, min(1, (introT - a[0]) / (b[0] - a[0]))); u = u * u * (3 - 2 * u)
        func L(_ k: Int) -> Float { a[k] + (b[k] - a[k]) * u }
        rig.position = SCNVector3(L(1), L(2), L(3)); yaw = L(4); pitch = L(5)
        if introT > 8.6 && !introDone {
            introDone = true
            UIView.animate(withDuration: 1) { self.cover.alpha = 1 }
            after(1.4) { self.night = 1; self.begin() }
        }
    }

    @objc func tick(_ l: CADisplayLink) {
        guard alive else { return }
        let dt = Float(min(l.targetTimestamp - l.timestamp, 0.1))
        tt += dt
        if state == 3 { intro(dt) }
        if state == 1 {
            let f = Float(-jv.y), s = Float(jv.x), sp: Float = 3
            let dx = (-sin(yaw) * f + cos(yaw) * s) * sp * dt
            let dz = (-cos(yaw) * f - sin(yaw) * s) * sp * dt
            let o = rig.position
            let nx = max(-bx, min(bx, o.x + dx)), nz = max(-bz, min(bz, o.z + dz))
            rig.position = SCNVector3(nx, o.y, nz)
            let st = hypot(nx - o.x, nz - o.z)
            dist += st; bob += st * 7; stepT -= dt
            if st > 0.005 && stepT <= 0 { stepT = 0.5; _ = Snd.play("step", 0.6) }
            if night == 1 && dist > 6 { drop() }
            if night == 2 {
                if monster == nil && abs(nz) > 10 { spawn() }
                if let m = monster { lead(m, dt) }
                if abs(nz) > 58 && state == 1 { win() }
            }
        }
        water?.diffuse.contentsTransform = SCNMatrix4Mult(SCNMatrix4MakeScale(1, 100, 1), SCNMatrix4MakeTranslation(0, tt * 0.04, 0))
        let amp: Float = fxOn ? 0.006 + shake + near * 0.02 : 0
        func r() -> Float { Float.random(in: -1...1) }
        rig.eulerAngles = SCNVector3(0, yaw, 0)
        cam.eulerAngles = SCNVector3(pitch + r() * amp, r() * amp * 0.5, r() * amp)
        cam.position = SCNVector3(r() * amp * 0.3, sin(bob) * 0.03, 0)
        shake = max(0, shake - dt * 0.06)
        if fxOn && Int(tt * 30) % 2 == 0 { grain.frame.origin = CGPoint(x: -CGFloat.random(in: 0...20), y: -CGFloat.random(in: 0...20)) }
    }

    override func touchesBegan(_ ts: Set<UITouch>, with e: UIEvent?) {
        for t in ts {
            let p = t.location(in: self)
            if p.x < bounds.midX && moveT == nil {
                moveT = t; moveStart = p; ring.center = p; dot.center = p; ring.alpha = 1; dot.alpha = 1
            } else if lookT == nil { lookT = t; lastLook = p }
        }
    }
    override func touchesMoved(_ ts: Set<UITouch>, with e: UIEvent?) {
        for t in ts {
            let p = t.location(in: self)
            if t == moveT {
                var dx = (p.x - moveStart.x) / 50, dy = (p.y - moveStart.y) / 50
                let m = hypot(dx, dy); if m > 1 { dx /= m; dy /= m }
                jv = CGPoint(x: dx, y: dy); dot.center = CGPoint(x: moveStart.x + dx * 50, y: moveStart.y + dy * 50)
            } else if t == lookT {
                if state == 1 {
                    yaw -= Float(p.x - lastLook.x) * 0.006 * sens
                    pitch = min(1.2, max(-1.2, pitch - Float(p.y - lastLook.y) * 0.006 * sens))
                }
                lastLook = p
            }
        }
    }
    override func touchesEnded(_ ts: Set<UITouch>, with e: UIEvent?) {
        for t in ts {
            if t == moveT { moveT = nil; jv = .zero; ring.alpha = 0; dot.alpha = 0 }
            if t == lookT { lookT = nil }
        }
    }
    override func touchesCancelled(_ ts: Set<UITouch>, with e: UIEvent?) { touchesEnded(ts, with: e) }
}

final class Menu: UIView {
    let box = UIView(), bg = UIImageView(), shade = UIView(), grain = UIView(), st: UIStackView
    init(_ items: [UIView], dim: CGFloat, _ sp: CGFloat) {
        st = UIStackView(arrangedSubviews: items)
        super.init(frame: .zero)
        backgroundColor = .black; box.clipsToBounds = true
        bg.image = img("menu", "jpg"); bg.contentMode = .scaleAspectFill
        shade.backgroundColor = UIColor(white: 0, alpha: dim)
        if let g = img("noise", "png")?.cgImage { grain.layer.contents = g }
        grain.layer.magnificationFilter = .nearest; grain.alpha = 0.55; grain.isUserInteractionEnabled = false
        st.axis = .vertical; st.spacing = sp; st.alignment = .center; st.translatesAutoresizingMaskIntoConstraints = false
        addSubview(box); [bg, shade, grain, st].forEach { box.addSubview($0) }
        st.centerXAnchor.constraint(equalTo: box.centerXAnchor).isActive = true
        st.centerYAnchor.constraint(equalTo: box.centerYAnchor, constant: dim > 0 ? 0 : 50).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        let h = min(bounds.height, bounds.width / 1.25), w = h * 1.25
        box.frame = CGRect(x: (bounds.width - w) / 2, y: (bounds.height - h) / 2, width: w, height: h)
        bg.frame = box.bounds; shade.frame = box.bounds; grain.frame = box.bounds.insetBy(dx: -20, dy: -20)
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] t in
            guard let s = self, s.window != nil else { t.invalidate(); return }
            s.grain.frame.origin = CGPoint(x: -CGFloat.random(in: 0...20), y: -CGFloat.random(in: 0...20))
        }
    }
}

final class Root: UIViewController {
    var player: AVAudioPlayer?
    var current: UIView?
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
            view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        if let u = Bundle.main.url(forResource: "music", withExtension: "m4a") ?? Bundle.main.url(forResource: "amb", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: u)
            player?.numberOfLoops = -1; player?.volume = vol; player?.play()
        }
        if lang.isEmpty { showLang() } else { showMenu() }
    }
    func show(_ v: UIView) {
        current?.removeFromSuperview()
        v.frame = view.bounds; v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(v); current = v
    }
    func item(_ t: String, _ sel: Bool, _ a: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(sel ? "▶  " + t : t, for: .normal); b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "Courier-Bold", size: 22) ?? .boldSystemFont(ofSize: 22)
        b.backgroundColor = sel ? UIColor(white: 0.1, alpha: 0.7) : .clear
        b.layer.shadowColor = UIColor.black.cgColor; b.layer.shadowOpacity = 1; b.layer.shadowRadius = 0; b.layer.shadowOffset = CGSize(width: 1, height: 1)
        b.addTarget(self, action: a, for: .touchUpInside)
        b.widthAnchor.constraint(equalToConstant: 230).isActive = true
        b.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return b
    }
    func label(_ t: String) -> UILabel {
        let l = UILabel(); l.text = t; l.textColor = .white
        l.font = UIFont(name: "Courier-Bold", size: 13) ?? .boldSystemFont(ofSize: 13); return l
    }
    func showLang() { show(Menu([item("English", true, #selector(setEn)), item("العربية", false, #selector(setAr))], dim: 0, 8)) }
    func showMenu() { show(Menu([item(T("play"), true, #selector(play)), item(T("settings"), false, #selector(openSettings))], dim: 0, 8)) }
    func showSettings() {
        let vs = UISlider(), ss = UISlider(), sw = UISwitch()
        vs.value = vol; vs.tag = 1; ss.minimumValue = 0.4; ss.maximumValue = 2; ss.value = sens; ss.tag = 2; sw.isOn = fxOn
        for s in [vs, ss] { s.addTarget(self, action: #selector(slid(_:)), for: .valueChanged); s.widthAnchor.constraint(equalToConstant: 220).isActive = true }
        sw.addTarget(self, action: #selector(fxChanged(_:)), for: .valueChanged)
        show(Menu([item(T("lang"), false, #selector(toggleLang)), label(T("vol")), vs, label(T("sens")), ss, label(T("fx")), sw,
                   item(T("back"), true, #selector(back))], dim: 0.55, 5))
    }
    @objc func setEn() { lang = "en"; showMenu() }
    @objc func setAr() { lang = "ar"; showMenu() }
    @objc func openSettings() { showSettings() }
    @objc func back() { showMenu() }
    @objc func toggleLang() { lang = (lang == "ar") ? "en" : "ar"; showSettings() }
    @objc func slid(_ s: UISlider) { if s.tag == 1 { vol = s.value; player?.volume = vol } else { sens = s.value } }
    @objc func fxChanged(_ s: UISwitch) { fxOn = s.isOn }
    @objc func play() {
        let g = GameView(frame: view.bounds)
        player?.pause()
        g.onExit = { [weak self] in self?.player?.play(); self?.showMenu() }
        show(g); g.start()
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ a: UIApplication, supportedInterfaceOrientationsFor w: UIWindow?) -> UIInterfaceOrientationMask { .landscape }
    func application(_ a: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = Root()
        window?.makeKeyAndVisible()
        return true
    }
}
