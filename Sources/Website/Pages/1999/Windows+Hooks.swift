import Elementary
import Foundation
import SiteKit

extension GeoCitiesWindows {
	/**
	The colors of a color scheme of the windows of the desktop, which `geocities-windows.js` sets on the desktop, and the windows and title bars of ``GeoCitiesPage`` read, so Hot Dog Stand only colors the windows of the desktop.
	*/
	static let titleStart = StyleVariable<Color>("--win-title-start")
	static let titleEnd = StyleVariable<Color>("--win-title-end")
	static let windowFace = StyleVariable<Color>("--win-face")
	static let windowText = StyleVariable<Color>("--win-text")

	enum Hooks: String, ScriptHookSet {
		/**
		A button that closes its window, like Cancel.
		*/
		case close = "data-win-close"

		/**
		An item of the Start menu that `geocities-windows.js` runs, like `logoff`.
		*/
		case command = "data-win-command"

		/**
		An item of the Start menu that opens its submenu, like `programs`.
		*/
		case submenu = "data-win-submenu"

		case tasks = "geocities-win-tasks"
		case taskTemplate = "geocities-win-task-template"
		case tray = "geocities-win-tray"
		case onlineButton = "geocities-win-online"
		case mailButton = "geocities-win-mail"
		case volumeButton = "geocities-win-volume-button"
		case volume = "geocities-win-volume"
		case volumeLevel = "geocities-win-volume-level"
		case mute = "geocities-win-mute"

		/**
		On the desktop while it shows large icons.
		*/
		case largeIcons = "data-win-large-icons"

		/**
		On the desktop while the Active Desktop shows it as a web page.
		*/
		case web = "data-win-web"

		/**
		On the desktop while Windows is busy, which shows the hourglass.
		*/
		case busy = "data-win-busy"

		/**
		On the desktop while CLEAN.AVI plays, which makes the icons and the taskbar dance.
		*/
		case dancing = "data-win-dancing"

		/**
		On a window that is not responding.
		*/
		case frozen = "data-win-frozen"

		/**
		On a button that is picked, like a column of FreeCell.
		*/
		case selected = "data-win-selected"

		case calcDisplay = "geocities-win-calc-display"
		case calcMemory = "geocities-win-calc-memory"
		case calcKey = "data-win-calc-key"
		case calcFlip = "geocities-win-calc-flip"
		case calcStatus = "geocities-win-calc-status"

		/**
		On the display of Calculator while it is upside down.
		*/
		case flipped = "data-win-flipped"

		case dosOutput = "geocities-win-dos-output"
		case dosForm = "geocities-win-dos-form"
		case dosPrompt = "geocities-win-dos-prompt"
		case dosInput = "geocities-win-dos-input"

		case wordpadFont = "geocities-win-wordpad-font"
		case wordpadSize = "geocities-win-wordpad-size"
		case wordpadFormat = "data-win-wordpad-format"
		case wordpadText = "geocities-win-wordpad-text"
		case wordpadWingdings = "geocities-win-wordpad-wingdings"
		case wordpadStatus = "geocities-win-wordpad-status"
		case assistant = "geocities-win-assistant"
		case assistantText = "geocities-win-assistant-text"
		case assistantChoice = "data-win-assistant-choice"

		case ieAction = "data-win-ie-action"
		case ieForm = "geocities-win-ie-form"
		case ieAddress = "geocities-win-ie-address"
		case iePage = "geocities-win-ie-page"
		case ieStatus = "geocities-win-ie-status"
		case ieProgress = "geocities-win-ie-progress"

		/**
		A page of Internet Explorer, by its name, like `error`.
		*/
		case iePageTemplate = "data-win-ie-template"

		/**
		A link on a page of Internet Explorer, with its address.
		*/
		case ieGo = "data-win-ie-go"

		/**
		Where a page of Internet Explorer shows the address.
		*/
		case ieSlot = "data-win-ie-slot"

		/**
		On Internet Explorer while a page loads, which spins the logo.
		*/
		case loading = "data-win-loading"

		case dialUpConnect = "geocities-win-dialup-connect"
		case dialUpDisconnect = "geocities-win-dialup-disconnect"
		case dialUpStatus = "geocities-win-dialup-status"

		case documentsList = "geocities-win-documents-list"
		case documentsStatus = "geocities-win-documents-status"
		case folderList = "geocities-win-folder-list"
		case folderStatus = "geocities-win-folder-status"
		case networkUp = "geocities-win-network-up"
		case networkPath = "geocities-win-network-path"
		case networkList = "geocities-win-network-list"
		case networkStatus = "geocities-win-network-status"
		case viewerText = "geocities-win-viewer-text"
		case fileTemplate = "geocities-win-file-template"
		case iconTemplate = "geocities-win-icon-template"
		case restoreTemplate = "geocities-win-restore-template"

		case mediaVideo = "geocities-win-media-video"

		/**
		The address of the GIF that plays while Media Player plays.
		*/
		case mediaAnimated = "data-win-media-animated"

		case mediaBuffering = "geocities-win-media-buffering"
		case mediaAction = "data-win-media-action"
		case mediaProgress = "geocities-win-media-progress"
		case mediaTime = "geocities-win-media-time"
		case mediaStatus = "geocities-win-media-status"

		case soundPosition = "geocities-win-sound-position"
		case soundWave = "geocities-win-sound-wave"
		case soundLength = "geocities-win-sound-length"
		case soundAction = "data-win-sound-action"
		case soundEffect = "data-win-sound-effect"
		case soundStatus = "geocities-win-sound-status"

		case freecellCell = "data-win-freecell-cell"
		case freecellHome = "data-win-freecell-home"
		case freecellColumn = "data-win-freecell-column"
		case freecellKing = "geocities-win-freecell-king"
		case freecellForm = "geocities-win-freecell-form"
		case freecellUndo = "geocities-win-freecell-undo"
		case freecellNumber = "geocities-win-freecell-number"
		case freecellRandom = "geocities-win-freecell-random"
		case freecellStatus = "geocities-win-freecell-status"
		case cardTemplate = "geocities-win-card-template"

		/**
		On a red card, a heart or a diamond.
		*/
		case cardRed = "data-win-card-red"

		/**
		On the king of FreeCell while he looks to the right, at the home cells.
		*/
		case lookRight = "data-win-look-right"

		case controlHome = "geocities-win-control-home"
		case controlOpen = "data-win-control-open"
		case controlPane = "data-win-control-pane"
		case controlBack = "data-win-control-back"
		case controlStatus = "geocities-win-control-status"
		case wallpaperPicker = "geocities-win-wallpaper"
		case scheme = "geocities-win-scheme"
		case saver = "geocities-win-saver"
		case saverPreview = "geocities-win-saver-preview"
		case largeIconsToggle = "geocities-win-large-icons"
		case webToggle = "geocities-win-web"
		case theme = "geocities-win-theme"
		case themeSounds = "geocities-win-theme-sounds"
		case dateMonth = "geocities-win-date-month"
		case dateYear = "geocities-win-date-year"
		case dateDay = "data-win-date-day"

		/**
		On the day of the calendar that is today.
		*/
		case today = "data-win-today"

		case dateApply = "geocities-win-date-apply"
		case jackBox = "geocities-win-jack-box"
		case doubleClickSpeed = "geocities-win-double-click-speed"
		case hardwareText = "geocities-win-hardware-text"
		case hardwareProgress = "geocities-win-hardware-progress"
		case hardwareNext = "geocities-win-hardware-next"
		case removeProgram = "data-win-remove-program"

		case fixerText = "geocities-win-fixer-text"
		case fixerProgress = "geocities-win-fixer-progress"
		case fixerStart = "geocities-win-fixer-start"

		case findForm = "geocities-win-find-form"
		case findName = "geocities-win-find-name"
		case findAnimation = "geocities-win-find-animation"
		case findResults = "geocities-win-find-results"
		case findStatus = "geocities-win-find-status"

		case runForm = "geocities-win-run-form"
		case runInput = "geocities-win-run-input"
		case runBrowse = "geocities-win-run-browse"

		case tasksList = "geocities-win-tasks-list"
		case tasksEnd = "geocities-win-tasks-end"
		case tasksShutDown = "geocities-win-tasks-shut-down"
		case tasksStatus = "geocities-win-tasks-status"

		case welcomeTopic = "data-win-welcome-topic"
		case welcomeText = "geocities-win-welcome-text"
		case welcomeNext = "geocities-win-welcome-next"
		case welcomeShow = "geocities-win-welcome-show"

		case logOnForm = "geocities-win-logon-form"
		case logOnUser = "geocities-win-logon-user"
		case logOnPassword = "geocities-win-logon-password"
		case logOnCancel = "geocities-win-logon-cancel"

		case messageIcon = "geocities-win-message-icon"
		case messageText = "geocities-win-message-text"
		case messageDetails = "geocities-win-message-details"
		case messageButton = "data-win-message-button"

		case layer = "geocities-win-layer"
		case webPage = "geocities-win-web-page"
		case recoveryPage = "geocities-win-recovery-page"
		case channels = "geocities-win-channels"
		case channel = "data-win-channel"
		case ticker = "geocities-win-ticker"
		case tickerText = "geocities-win-ticker-text"
		case recovery = "geocities-win-recovery"
		case recoveryRestore = "geocities-win-recovery-restore"
		case contextMenu = "geocities-win-context-menu"
		case contextCommand = "data-win-context-command"

		/**
		What an item of the menu of the right mouse button is for: `icon` or `desktop`.
		*/
		case contextTarget = "data-win-context-target"

		case boot = "geocities-win-boot"
		case bootText = "geocities-win-boot-text"
		case bootLogo = "geocities-win-boot-logo"
		case bsod = "geocities-win-bsod"
		case bsodQuote = "geocities-win-bsod-quote"
		case maze = "geocities-win-maze"
		case shutDownForm = "geocities-win-shut-down-form"

		/**
		A choice of Shut Down Windows, like `standby`.
		*/
		case shutDownChoice = "data-win-shut-down-choice"

		case showDesktop = "geocities-win-show-desktop"
		case beginHint = "geocities-win-begin-hint"
		case cat = "geocities-win-cat"
		case paperTemplate = "geocities-win-paper-template"
		case marqueeText = "geocities-win-marquee-text"
		case shyIcons = "geocities-win-shy-icons"

		/**
		On the desktop while Show Desktop hides the windows.
		*/
		case desktopShown = "data-win-desktop-shown"

		/**
		On the desktop while Shut Down Windows asks, which makes the screen behind it gray, like Windows 98.
		*/
		case dimmed = "data-win-dimmed"

		/**
		On the desktop in MS-DOS mode, where the MS-DOS Prompt fills the screen.
		*/
		case dosMode = "data-win-dos-mode"
		case mazeCanvas = "geocities-win-maze-canvas"
		case mazeText = "geocities-win-maze-text"
	}
}
