import Foundation
import UIKit
import Display
import ComponentFlow
import AppBundle
import TextFieldComponent
import BundleIconComponent
import AccountContext
import TelegramPresentationData
import ChatPresentationInterfaceState

public final class MessageInputPanelComponent: Component {
    public enum Style {
        case story
        case editor
    }
    public final class ExternalState {
        public fileprivate(set) var isEditing: Bool = false
        public fileprivate(set) var hasText: Bool = false
        
        public init() {
        }
    }
    
    public let externalState: ExternalState
    public let context: AccountContext
    public let theme: PresentationTheme
    public let strings: PresentationStrings
    public let style: Style
    public let placeholder: String
    public let presentController: (ViewController) -> Void
    public let sendMessageAction: () -> Void
    public let setMediaRecordingActive: ((Bool, Bool, Bool) -> Void)?
    public let attachmentAction: (() -> Void)?
    public let reactionAction: ((UIView) -> Void)?
    public let audioRecorder: ManagedAudioRecorder?
    public let videoRecordingStatus: InstantVideoControllerRecordingStatus?
    public let displayGradient: Bool
    public let bottomInset: CGFloat
    
    public init(
        externalState: ExternalState,
        context: AccountContext,
        theme: PresentationTheme,
        strings: PresentationStrings,
        style: Style,
        placeholder: String,
        presentController: @escaping (ViewController) -> Void,
        sendMessageAction: @escaping () -> Void,
        setMediaRecordingActive: ((Bool, Bool, Bool) -> Void)?,
        attachmentAction: (() -> Void)?,
        reactionAction: ((UIView) -> Void)?,
        audioRecorder: ManagedAudioRecorder?,
        videoRecordingStatus: InstantVideoControllerRecordingStatus?,
        displayGradient: Bool,
        bottomInset: CGFloat
    ) {
        self.externalState = externalState
        self.context = context
        self.theme = theme
        self.strings = strings
        self.style = style
        self.placeholder = placeholder
        self.presentController = presentController
        self.sendMessageAction = sendMessageAction
        self.setMediaRecordingActive = setMediaRecordingActive
        self.attachmentAction = attachmentAction
        self.reactionAction = reactionAction
        self.audioRecorder = audioRecorder
        self.videoRecordingStatus = videoRecordingStatus
        self.displayGradient = displayGradient
        self.bottomInset = bottomInset
    }
    
    public static func ==(lhs: MessageInputPanelComponent, rhs: MessageInputPanelComponent) -> Bool {
        if lhs.externalState !== rhs.externalState {
            return false
        }
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        if lhs.style != rhs.style {
            return false
        }
        if lhs.placeholder != rhs.placeholder {
            return false
        }
        if lhs.audioRecorder !== rhs.audioRecorder {
            return false
        }
        if lhs.videoRecordingStatus !== rhs.videoRecordingStatus {
            return false
        }
        if lhs.displayGradient != rhs.displayGradient {
            return false
        }
        if lhs.bottomInset != rhs.bottomInset {
            return false
        }
        return true
    }
    
    public enum SendMessageInput {
        case text(String)
    }
    
    public final class View: UIView {
        private let fieldBackgroundView: BlurredBackgroundView
        private let vibrancyEffectView: UIVisualEffectView
        private let gradientView: UIImageView
        private let bottomGradientView: UIView
        
        private let placeholder = ComponentView<Empty>()
        private let vibrancyPlaceholder = ComponentView<Empty>()
        
        private let textField = ComponentView<Empty>()
        private let textFieldExternalState = TextFieldComponent.ExternalState()
        
        private let attachmentButton = ComponentView<Empty>()
        private let inputActionButton = ComponentView<Empty>()
        private let stickerButton = ComponentView<Empty>()
        private let reactionButton = ComponentView<Empty>()
        
        private var mediaRecordingPanel: ComponentView<Empty>?
        private weak var dismissingMediaRecordingPanel: UIView?
        
        private var currentMediaInputIsVoice: Bool = true
        private var mediaCancelFraction: CGFloat = 0.0
        
        private var component: MessageInputPanelComponent?
        private weak var state: EmptyComponentState?
        
        override init(frame: CGRect) {
            self.fieldBackgroundView = BlurredBackgroundView(color: UIColor(white: 0.0, alpha: 0.5), enableBlur: true)
            
            let style: UIBlurEffect.Style = .dark
            let blurEffect = UIBlurEffect(style: style)
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            self.vibrancyEffectView = vibrancyEffectView
            
            self.gradientView = UIImageView()
            self.bottomGradientView = UIView()
            
            super.init(frame: frame)
            
            self.addSubview(self.bottomGradientView)
            self.addSubview(self.gradientView)
            self.fieldBackgroundView.addSubview(self.vibrancyEffectView)
            self.addSubview(self.fieldBackgroundView)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public func getSendMessageInput() -> SendMessageInput {
            guard let textFieldView = self.textField.view as? TextFieldComponent.View else {
                return .text("")
            }
            
            return .text(textFieldView.getText())
        }
        
        public func getAttachmentButtonView() -> UIView? {
            guard let attachmentButtonView = self.attachmentButton.view else {
                return nil
            }
            return attachmentButtonView
        }
        
        public func clearSendMessageInput() {
            if let textFieldView = self.textField.view as? TextFieldComponent.View {
                textFieldView.setText(string: "")
            }
        }
        
        func update(component: MessageInputPanelComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
            var insets = UIEdgeInsets(top: 14.0, left: 7.0, bottom: 6.0, right: 7.0)
            if let _ = component.attachmentAction {
                insets.left = 41.0
            }
            if let _ = component.setMediaRecordingActive {
                insets.right = 41.0
            }
            let baseFieldHeight: CGFloat = 40.0
            
            self.component = component
            self.state = state

            let hasMediaRecording = component.audioRecorder != nil || component.videoRecordingStatus != nil
            
            let topGradientHeight: CGFloat = 32.0
            if self.gradientView.image == nil {
                let baseAlpha: CGFloat = 0.7
                
                self.gradientView.image = generateImage(CGSize(width: insets.left + insets.right + baseFieldHeight, height: topGradientHeight + insets.top + baseFieldHeight + insets.bottom), rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))
                    
                    var locations: [CGFloat] = []
                    var colors: [CGColor] = []
                    let numStops = 10
                    for i in 0 ..< numStops {
                        let step = 1.0 - CGFloat(i) / CGFloat(numStops - 1)
                        locations.append((1.0 - step))
                        let alphaStep: CGFloat = pow(step, 1.5)
                        colors.append(UIColor.black.withAlphaComponent(alphaStep * baseAlpha).cgColor)
                    }
                    
                    if let gradient = CGGradient(colorsSpace: context.colorSpace, colors: colors as CFArray, locations: &locations) {
                        context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: size.height), end: CGPoint(x: 0.0, y: 0.0), options: CGGradientDrawingOptions())
                    }
                    
                    context.setBlendMode(.copy)
                    context.setFillColor(UIColor.clear.cgColor)
                    context.fillEllipse(in: CGRect(origin: CGPoint(x: insets.left, y: topGradientHeight + insets.top), size: CGSize(width: baseFieldHeight, height: baseFieldHeight)).insetBy(dx: 3.0, dy: 3.0))
                })?.resizableImage(withCapInsets: UIEdgeInsets(top: topGradientHeight + insets.top + baseFieldHeight * 0.5, left: insets.left + baseFieldHeight * 0.5, bottom: insets.bottom + baseFieldHeight * 0.5, right: insets.right + baseFieldHeight * 0.5))
                
                self.bottomGradientView.backgroundColor = UIColor.black.withAlphaComponent(baseAlpha)
            }
            
            let availableTextFieldSize = CGSize(width: availableSize.width - insets.left - insets.right, height: availableSize.height - insets.top - insets.bottom)
            
            self.textField.parentState = state
            let textFieldSize = self.textField.update(
                transition: .immediate,
                component: AnyComponent(TextFieldComponent(
                    externalState: self.textFieldExternalState,
                    placeholder: ""
                )),
                environment: {},
                containerSize: availableTextFieldSize
            )
            
            let placeholderSize = self.placeholder.update(
                transition: .immediate,
                component: AnyComponent(Text(
                    text: component.placeholder,
                    font: Font.regular(17.0),
                    color: UIColor(rgb: 0xffffff, alpha: 0.3)
                )),
                environment: {},
                containerSize: availableTextFieldSize
            )
            
            let _ = self.vibrancyPlaceholder.update(
                transition: .immediate,
                component: AnyComponent(Text(
                    text: component.placeholder,
                    font: Font.regular(17.0),
                    color: .white
                )),
                environment: {},
                containerSize: availableTextFieldSize
            )
            if self.textFieldExternalState.isEditing {
                insets.right = 41.0
            }
            
            let fieldFrame = CGRect(origin: CGPoint(x: insets.left, y: insets.top), size: CGSize(width: availableSize.width - insets.left - insets.right, height: textFieldSize.height))
            transition.setFrame(view: self.vibrancyEffectView, frame: CGRect(origin: CGPoint(), size: fieldFrame.size))
            transition.setAlpha(view: self.vibrancyEffectView, alpha: (component.audioRecorder != nil || component.videoRecordingStatus != nil) ? 0.0 : 1.0)
            
            transition.setFrame(view: self.fieldBackgroundView, frame: fieldFrame)
            self.fieldBackgroundView.update(size: fieldFrame.size, cornerRadius: baseFieldHeight * 0.5, transition: transition.containedViewLayoutTransition)
            
            let gradientFrame = CGRect(origin: CGPoint(x: 0.0, y: -topGradientHeight), size: CGSize(width: availableSize.width, height: topGradientHeight + fieldFrame.maxY + insets.bottom))
            transition.setFrame(view: self.gradientView, frame: gradientFrame)
            transition.setFrame(view: self.bottomGradientView, frame: CGRect(origin: CGPoint(x: 0.0, y: gradientFrame.maxY), size: CGSize(width: availableSize.width, height: component.bottomInset)))
            transition.setAlpha(view: self.gradientView, alpha: component.displayGradient ? 1.0 : 0.0)
            transition.setAlpha(view: self.bottomGradientView, alpha: component.displayGradient ? 1.0 : 0.0)

            let placeholderOriginX: CGFloat
            if self.textFieldExternalState.isEditing || component.style == .story {
                placeholderOriginX = 16.0
            } else {
                placeholderOriginX = floorToScreenPixels((availableSize.width - placeholderSize.width) / 2.0)
            }
            let placeholderFrame = CGRect(origin: CGPoint(x: placeholderOriginX, y: floor((fieldFrame.height - placeholderSize.height) * 0.5)), size: placeholderSize)
            if let placeholderView = self.placeholder.view, let vibrancyPlaceholderView = self.vibrancyPlaceholder.view {
                if vibrancyPlaceholderView.superview == nil {
                    vibrancyPlaceholderView.layer.anchorPoint = CGPoint()
                    self.vibrancyEffectView.contentView.addSubview(vibrancyPlaceholderView)
                }
                transition.setPosition(view: vibrancyPlaceholderView, position: placeholderFrame.origin)
                vibrancyPlaceholderView.bounds = CGRect(origin: CGPoint(), size: placeholderFrame.size)
                
                if placeholderView.superview == nil {
                    placeholderView.isUserInteractionEnabled = false
                    placeholderView.layer.anchorPoint = CGPoint()
                    self.fieldBackgroundView.addSubview(placeholderView)
                }
                transition.setPosition(view: placeholderView, position: placeholderFrame.origin)
                placeholderView.bounds = CGRect(origin: CGPoint(), size: placeholderFrame.size)
            }
            
            let size = CGSize(width: availableSize.width, height: textFieldSize.height + insets.top + insets.bottom)
            
            if let textFieldView = self.textField.view {
                if textFieldView.superview == nil {
                    self.addSubview(textFieldView)
                }
                transition.setFrame(view: textFieldView, frame: CGRect(origin: CGPoint(x: fieldFrame.minX, y: fieldFrame.maxY - textFieldSize.height), size: textFieldSize))
                transition.setAlpha(view: textFieldView, alpha: (component.audioRecorder != nil || component.videoRecordingStatus != nil) ? 0.0 : 1.0)
            }
            
            if let attachmentAction = component.attachmentAction {
                let attachmentButtonSize = self.attachmentButton.update(
                    transition: transition,
                    component: AnyComponent(Button(
                        content: AnyComponent(BundleIconComponent(
                            name: "Chat/Input/Text/IconAttachment",
                            tintColor: .white
                        )),
                        action: {
                            attachmentAction()
                        }
                    ).minSize(CGSize(width: 41.0, height: baseFieldHeight))),
                    environment: {},
                    containerSize: CGSize(width: 41.0, height: baseFieldHeight)
                )
                if let attachmentButtonView = self.attachmentButton.view {
                    if attachmentButtonView.superview == nil {
                        self.addSubview(attachmentButtonView)
                    }
                    transition.setFrame(view: attachmentButtonView, frame: CGRect(origin: CGPoint(x: floor((insets.left - attachmentButtonSize.width) * 0.5), y: size.height - insets.bottom - baseFieldHeight + floor((baseFieldHeight - attachmentButtonSize.height) * 0.5)), size: attachmentButtonSize))
                }
            }
            
            
            let inputActionButtonMode: MessageInputActionButtonComponent.Mode
            if case .editor = component.style {
                inputActionButtonMode = self.textFieldExternalState.isEditing ? .apply : .none
            } else {
                inputActionButtonMode = self.textFieldExternalState.hasText ? .send : (self.currentMediaInputIsVoice ? .voiceInput : .videoInput)
            }
            let inputActionButtonSize = self.inputActionButton.update(
                transition: transition,
                component: AnyComponent(MessageInputActionButtonComponent(
                    mode: inputActionButtonMode,
                    action: { [weak self] mode, action, sendAction in
                        guard let self else {
                            return
                        }
                        
                        switch mode {
                        case .none:
                            break
                        case .send:
                            if case .up = action {
                                if case .text("") = self.getSendMessageInput() {
                                } else {
                                    self.component?.sendMessageAction()
                                }
                            }
                        case .apply:
                            if case .up = action {
                                self.component?.sendMessageAction()
                            }
                        case .voiceInput, .videoInput:
                            self.component?.setMediaRecordingActive?(action == .down, mode == .videoInput, sendAction)
                        }
                    },
                    switchMediaInputMode: { [weak self] in
                        guard let self else {
                            return
                        }
                        self.currentMediaInputIsVoice = !self.currentMediaInputIsVoice
                        self.state?.updated(transition: Transition(animation: .curve(duration: 0.4, curve: .spring)))
                    },
                    updateMediaCancelFraction: { [weak self] mediaCancelFraction in
                        guard let self else {
                            return
                        }
                        if self.mediaCancelFraction != mediaCancelFraction {
                            self.mediaCancelFraction = mediaCancelFraction
                            self.state?.updated(transition: .immediate)
                        }
                    },
                    context: component.context,
                    theme: component.theme,
                    strings: component.strings,
                    presentController: component.presentController,
                    audioRecorder: component.audioRecorder,
                    videoRecordingStatus: component.videoRecordingStatus
                )),
                environment: {},
                containerSize: CGSize(width: 33.0, height: 33.0)
            )
            if let inputActionButtonView = self.inputActionButton.view {
                if inputActionButtonView.superview == nil {
                    self.addSubview(inputActionButtonView)
                }
                let inputActionButtonOriginX: CGFloat
                if component.setMediaRecordingActive != nil || self.textFieldExternalState.isEditing {
                    inputActionButtonOriginX = size.width - insets.right + floorToScreenPixels((insets.right - inputActionButtonSize.width) * 0.5)
                } else {
                    inputActionButtonOriginX = size.width
                }
                transition.setFrame(view: inputActionButtonView, frame: CGRect(origin: CGPoint(x: inputActionButtonOriginX, y: size.height - insets.bottom - baseFieldHeight + floorToScreenPixels((baseFieldHeight - inputActionButtonSize.height) * 0.5)), size: inputActionButtonSize))
            }
        
            var fieldIconNextX = fieldFrame.maxX - 2.0
            if case .story = component.style {
                let stickerButtonSize = self.stickerButton.update(
                    transition: transition,
                    component: AnyComponent(Button(
                        content: AnyComponent(BundleIconComponent(
                            name: "Chat/Input/Text/AccessoryIconStickers",
                            tintColor: .white
                        )),
                        action: { [weak self] in
                            guard let self else {
                                return
                            }
                            self.component?.attachmentAction?()
                        }
                    ).minSize(CGSize(width: 32.0, height: 32.0))),
                    environment: {},
                    containerSize: CGSize(width: 32.0, height: 32.0)
                )
                if let stickerButtonView = self.stickerButton.view {
                    if stickerButtonView.superview == nil {
                        self.addSubview(stickerButtonView)
                    }
                    let stickerIconFrame = CGRect(origin: CGPoint(x: fieldIconNextX - stickerButtonSize.width, y: fieldFrame.minY + floor((fieldFrame.height - stickerButtonSize.height) * 0.5)), size: stickerButtonSize)
                    transition.setPosition(view: stickerButtonView, position: stickerIconFrame.center)
                    transition.setBounds(view: stickerButtonView, bounds: CGRect(origin: CGPoint(), size: stickerIconFrame.size))
                    
                    transition.setAlpha(view: stickerButtonView, alpha: (self.textFieldExternalState.hasText || hasMediaRecording) ? 0.0 : 1.0)
                    transition.setScale(view: stickerButtonView, scale: self.textFieldExternalState.hasText ? 0.1 : 1.0)
                    
                    fieldIconNextX -= stickerButtonSize.width + 2.0
                }
            }
            
            if let reactionAction = component.reactionAction {
                let reactionButtonSize = self.reactionButton.update(
                    transition: transition,
                    component: AnyComponent(Button(
                        content: AnyComponent(BundleIconComponent(
                            name: "Chat/Input/Text/AccessoryIconReaction",
                            tintColor: .white
                        )),
                        action: { [weak self] in
                            guard let self, let reactionButtonView = self.reactionButton.view else {
                                return
                            }
                            reactionAction(reactionButtonView)
                        }
                    ).minSize(CGSize(width: 32.0, height: 32.0))),
                    environment: {},
                    containerSize: CGSize(width: 32.0, height: 32.0)
                )
                if let reactionButtonView = self.reactionButton.view {
                    if reactionButtonView.superview == nil {
                        self.addSubview(reactionButtonView)
                    }
                    let reactionIconFrame = CGRect(origin: CGPoint(x: fieldIconNextX - reactionButtonSize.width, y: fieldFrame.minY + 1.0 + floor((fieldFrame.height - reactionButtonSize.height) * 0.5)), size: reactionButtonSize)
                    transition.setPosition(view: reactionButtonView, position: reactionIconFrame.center)
                    transition.setBounds(view: reactionButtonView, bounds: CGRect(origin: CGPoint(), size: reactionIconFrame.size))
                    
                    transition.setAlpha(view: reactionButtonView, alpha: (self.textFieldExternalState.hasText || hasMediaRecording) ? 0.0 : 1.0)
                    transition.setScale(view: reactionButtonView, scale: self.textFieldExternalState.hasText ? 0.1 : 1.0)
                    
                    fieldIconNextX -= reactionButtonSize.width + 2.0
                }
            }
            
            self.fieldBackgroundView.updateColor(color: self.textFieldExternalState.isEditing || component.style == .editor ? UIColor(white: 0.0, alpha: 0.5) : UIColor(white: 1.0, alpha: 0.09), transition: transition.containedViewLayoutTransition)
            transition.setAlpha(view: self.fieldBackgroundView, alpha: hasMediaRecording ? 0.0 : 1.0)
            if let placeholder = self.placeholder.view, let vibrancyPlaceholderView = self.vibrancyPlaceholder.view {
                placeholder.isHidden = self.textFieldExternalState.hasText
                vibrancyPlaceholderView.isHidden = placeholder.isHidden
            }
            
            component.externalState.isEditing = self.textFieldExternalState.isEditing
            component.externalState.hasText = self.textFieldExternalState.hasText
            
            if component.audioRecorder != nil || component.videoRecordingStatus != nil {
                if let dismissingMediaRecordingPanel = self.dismissingMediaRecordingPanel {
                    self.dismissingMediaRecordingPanel = nil
                    transition.setAlpha(view: dismissingMediaRecordingPanel, alpha: 0.0, completion: { [weak dismissingMediaRecordingPanel] _ in
                        dismissingMediaRecordingPanel?.removeFromSuperview()
                    })
                }
                
                let mediaRecordingPanel: ComponentView<Empty>
                var mediaRecordingPanelTransition = transition
                if let current = self.mediaRecordingPanel {
                    mediaRecordingPanel = current
                } else {
                    mediaRecordingPanelTransition = .immediate
                    mediaRecordingPanel = ComponentView()
                    self.mediaRecordingPanel = mediaRecordingPanel
                }
                
                let _ = mediaRecordingPanel.update(
                    transition: mediaRecordingPanelTransition,
                    component: AnyComponent(MediaRecordingPanelComponent(
                        audioRecorder: component.audioRecorder,
                        videoRecordingStatus: component.videoRecordingStatus,
                        cancelFraction: self.mediaCancelFraction,
                        insets: insets
                    )),
                    environment: {},
                    containerSize: size
                )
                if let mediaRecordingPanelView = mediaRecordingPanel.view as? MediaRecordingPanelComponent.View {
                    var animateIn = false
                    if mediaRecordingPanelView.superview == nil {
                        animateIn = true
                        self.insertSubview(mediaRecordingPanelView, at: 0)
                    }
                    mediaRecordingPanelTransition.setFrame(view: mediaRecordingPanelView, frame: CGRect(origin: CGPoint(), size: size))
                    if animateIn && !transition.animation.isImmediate {
                        mediaRecordingPanelView.animateIn()
                    }
                }
                
                if let attachmentButtonView = self.attachmentButton.view {
                    transition.setAlpha(view: attachmentButtonView, alpha: 0.0)
                }
            } else {
                if let mediaRecordingPanel = self.mediaRecordingPanel {
                    self.mediaRecordingPanel = nil
                    
                    if let dismissingMediaRecordingPanel = self.dismissingMediaRecordingPanel {
                        self.dismissingMediaRecordingPanel = nil
                        transition.setAlpha(view: dismissingMediaRecordingPanel, alpha: 0.0, completion: { [weak dismissingMediaRecordingPanel] _ in
                            dismissingMediaRecordingPanel?.removeFromSuperview()
                        })
                    }
                    
                    self.dismissingMediaRecordingPanel = mediaRecordingPanel.view
                    
                    if let mediaRecordingPanelView = mediaRecordingPanel.view as? MediaRecordingPanelComponent.View {
                        mediaRecordingPanelView.animateOut(dismissRecording: true, completion: { [weak self, weak mediaRecordingPanelView] in
                            let transition = Transition(animation: .curve(duration: 0.3, curve: .spring))
                            
                            if let mediaRecordingPanelView = mediaRecordingPanelView {
                                transition.setAlpha(view: mediaRecordingPanelView, alpha: 0.0, completion: { [weak mediaRecordingPanelView] _ in
                                    mediaRecordingPanelView?.removeFromSuperview()
                                })
                            }
                            
                            guard let self else {
                                return
                            }
                            if self.mediaRecordingPanel == nil, let attachmentButtonView = self.attachmentButton.view {
                                transition.setAlpha(view: attachmentButtonView, alpha: 1.0)
                                transition.animateScale(view: attachmentButtonView, from: 0.001, to: 1.0)
                            }
                        })
                    }
                }
            }
            
            return size
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
