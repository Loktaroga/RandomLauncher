import UIKit

final class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    private let startPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .time
        if #available(iOS 13.4, *) { p.preferredDatePickerStyle = .wheels }
        p.locale = Locale(identifier: "zh_CN")
        return p
    }()

    private let endPicker: UIDatePicker = {
        let p = UIDatePicker()
        p.datePickerMode = .time
        if #available(iOS 13.4, *) { p.preferredDatePickerStyle = .wheels }
        p.locale = Locale(identifier: "zh_CN")
        return p
    }()

    private let countField = UITextField()
    private let bundleField = UITextField()
    private let returnField = UITextField()
    private let appPicker = UIPickerView()
    private var apps: [InstalledApp] = []

    private let repeatSwitch: UISwitch = {
        let s = UISwitch()
        s.isOn = true
        return s
    }()
    private let returnSwitch: UISwitch = {
        let s = UISwitch()
        s.isOn = true
        return s
    }()
    private let startButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadApps()
        loadDefaults()
    }

    private func setupUI() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        let title = UILabel()
        title.text = "RandomLauncher"
        title.font = .systemFont(ofSize: 30, weight: .bold)
        stack.addArrangedSubview(title)

        let subtitle = UILabel()
        subtitle.text = "在指定时段内随机拉起 App"
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabel
        stack.addArrangedSubview(subtitle)

        stack.addArrangedSubview(card(titleText: "开始时间", view: startPicker))
        stack.addArrangedSubview(card(titleText: "结束时间", view: endPicker))

        stack.addArrangedSubview(switchCard(titleText: "每天重复", sw: repeatSwitch))
        stack.addArrangedSubview(switchCard(titleText: "拉起后回到本 App", sw: returnSwitch))
        returnSwitch.addTarget(self, action: #selector(returnSwitchChanged), for: .valueChanged)
        updateReturnFieldState()

        returnField.borderStyle = .roundedRect
        returnField.placeholder = "停留秒数"
        returnField.keyboardType = .numberPad
        returnField.text = "5"
        stack.addArrangedSubview(fieldCard(titleText: "停留秒数（仅“回到本 App”生效）", field: returnField))

        countField.borderStyle = .roundedRect
        countField.placeholder = "触发次数"
        countField.keyboardType = .numberPad
        stack.addArrangedSubview(fieldCard(titleText: "触发次数", field: countField))

        // 目标 App：从本机已安装列表选择
        appPicker.dataSource = self
        appPicker.delegate = self
        stack.addArrangedSubview(card(titleText: "目标 App（从本机选择）", view: appPicker))

        bundleField.borderStyle = .roundedRect
        bundleField.placeholder = "目标 App Bundle ID（可手填覆盖）"
        bundleField.autocapitalizationType = .none
        bundleField.autocorrectionType = .no
        stack.addArrangedSubview(fieldCard(titleText: "目标 App Bundle ID", field: bundleField))

        startButton.setTitle("开始排程", for: .normal)
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        stack.addArrangedSubview(startButton)

        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(statusLabel)
    }

    // MARK: - 本机 App 列表

    private func loadApps() {
        apps = Launcher.installedApps()
        appPicker.reloadAllComponents()
        if !apps.isEmpty {
            appPicker.selectRow(0, inComponent: 0, animated: false)
            bundleField.text = apps[0].bundleID
        } else {
            // 非真机/无权限时降级为手填
            bundleField.text = "com.apple.MobileSafari"
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { apps.count }
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int, forComponent component: Int) -> String? {
        guard apps.indices.contains(row) else { return nil }
        return "\(apps[row].name)  (\(apps[row].bundleID))"
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard apps.indices.contains(row) else { return }
        bundleField.text = apps[row].bundleID
    }

    // MARK: - UI 卡片

    private func card(titleText: String, view: UIView) -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        let label = UILabel()
        label.text = titleText
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        view.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label)
        v.addSubview(view)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: v.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 14),
            view.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
            view.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 14),
            view.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -14),
            view.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -10)
        ])
        return v
    }

    private func fieldCard(titleText: String, field: UITextField) -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        let label = UILabel()
        label.text = titleText
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        field.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label)
        v.addSubview(field)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: v.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 14),
            field.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
            field.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 14),
            field.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -14),
            field.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -10)
        ])
        return v
    }

    private func switchCard(titleText: String, sw: UISwitch) -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        let label = UILabel()
        label.text = titleText
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        sw.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label)
        v.addSubview(sw)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            sw.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -14),
            sw.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            v.heightAnchor.constraint(equalToConstant: 52)
        ])
        return v
    }

    private func loadDefaults() {
        let d = UserDefaults.standard
        if let s = d.object(forKey: "startDate") as? Date { startPicker.date = s }
        else { startPicker.date = date(hour: 9, minute: 0) }
        if let e = d.object(forKey: "endDate") as? Date { endPicker.date = e }
        else { endPicker.date = date(hour: 21, minute: 0) }
        countField.text = d.string(forKey: "count") ?? "1"
        returnField.text = d.string(forKey: "returnSec") ?? "5"
        bundleField.text = d.string(forKey: "bundle") ?? "com.apple.MobileSafari"
        repeatSwitch.isOn = !d.bool(forKey: "repeatOff")
        returnSwitch.isOn = !d.bool(forKey: "returnOff")
        updateReturnFieldState()
    }

    private func date(hour: Int, minute: Int) -> Date {
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comp.hour = hour; comp.minute = minute; comp.second = 0
        return Calendar.current.date(from: comp) ?? Date()
    }

    /// 把滚轮选出的时分归一到“今天”，传给 Launcher。
    private func normalizedDate(from picker: UIDatePicker) -> Date {
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let pc = Calendar.current.dateComponents([.hour, .minute], from: picker.date)
        comp.hour = pc.hour; comp.minute = pc.minute; comp.second = 0
        return Calendar.current.date(from: comp) ?? Date()
    }

    @objc private func returnSwitchChanged() {
        updateReturnFieldState()
    }

    /// 「拉起后回到本 App」关闭时，停留秒数无意义，置灰禁用。
    private func updateReturnFieldState() {
        let on = returnSwitch.isOn
        returnField.isEnabled = on
        returnField.alpha = on ? 1.0 : 0.4
    }

    @objc private func startTapped() {
        let start = normalizedDate(from: startPicker)
        let end = normalizedDate(from: endPicker)
        guard let count = Int(countField.text ?? ""), count > 0 else {
            statusLabel.text = "请填写正确的正整数次数"
            return
        }
        let retAfter = TimeInterval(Int(returnField.text ?? "5") ?? 5)
        let bundle = (bundleField.text?.isEmpty == false) ? bundleField.text! : "com.apple.MobileSafari"

        let d = UserDefaults.standard
        d.set(startPicker.date, forKey: "startDate")
        d.set(endPicker.date, forKey: "endDate")
        d.set(countField.text, forKey: "count")
        d.set(returnField.text, forKey: "returnSec")
        d.set(bundle, forKey: "bundle")
        d.set(!repeatSwitch.isOn, forKey: "repeatOff")
        d.set(!returnSwitch.isOn, forKey: "returnOff")

        Launcher.shared.schedule(start: start, end: end, count: count, bundleID: bundle,
                                 repeatDaily: repeatSwitch.isOn,
                                 returnToSelf: returnSwitch.isOn,
                                 returnAfter: retAfter)

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let list = Launcher.shared.nextTimes.map { fmt.string(from: $0) }.joined(separator: "\n")
        let repeatText = repeatSwitch.isOn ? "（每天重复，跨天自动重置）" : "（仅今日）"
        let retText = returnSwitch.isOn ? "\n拉起后约 \(Int(retAfter)) 秒自动回到本 App" : ""
        statusLabel.text = "已排程 → \(bundle) \(repeatText)\n下次触发：\n" +
            (list.isEmpty ? "（今天该时段内已无可用时间）" : list) + retText
    }
}
