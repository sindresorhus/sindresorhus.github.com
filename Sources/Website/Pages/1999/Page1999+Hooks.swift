import Elementary
import Foundation
import SiteKit

extension GeoCitiesPage {
	/**
	The IDs and data attributes that `geocities.js` finds elements by.
	*/
	enum Hooks: String, ScriptHookSet {
		case game = "geocities-game"
		case start = "geocities-start"
		case clock = "geocities-clock"
		case score = "geocities-score"

		/**
		The number of a hole of the game, from 1 to 9, which is also its number key.
		*/
		case hole = "data-hole"

		case sparkleTemplate = "geocities-sparkle"
		case starTemplate = "geocities-star"
		case letterTemplate = "geocities-letter"

		/**
		The fun facts, the tunes of the jukebox, and the questions of the quiz, as JSON.
		*/
		case data = "geocities-data"

		case splash = "geocities-splash"
		case enter = "geocities-enter"
		case dialUp = "geocities-dial-up"
		case welcome = "geocities-welcome"

		case midiTune = "geocities-midi-tune"
		case midiPlay = "geocities-midi-play"
		case midiStop = "geocities-midi-stop"
		case midiStatus = "geocities-midi-status"

		case popUp = "geocities-pop-up"
		case popUpClose = "geocities-pop-up-close"
		case popUpClaim = "geocities-pop-up-claim"
		case popUpClosed = "geocities-pop-up-closed"

		case y2kDays = "geocities-y2k-days"
		case y2kToday = "geocities-y2k-today"
		case y2kCheck = "geocities-y2k-check"
		case y2kStatus = "geocities-y2k-status"

		case petFace = "geocities-pet-face"
		case petFood = "geocities-pet-food"
		case petFun = "geocities-pet-fun"
		case petStatus = "geocities-pet-status"

		/**
		What a button of Glitter does: `feed`, `play`, `brush`, `clean`, `trick`, `hat`, or `light`.
		*/
		case petAction = "data-pet-action"

		case petScreen = "geocities-pet-screen"
		case petStats = "geocities-pet-stats"
		case petBubble = "geocities-pet-bubble"
		case petHat = "geocities-pet-hat"
		case petSprite = "geocities-pet-sprite"
		case petZzz = "geocities-pet-zzz"
		case petMess = "geocities-pet-mess"
		case petGame = "geocities-pet-game"
		case petGameStatus = "geocities-pet-game-status"
		case petButtons = "geocities-pet-buttons"
		case petHeartTemplate = "geocities-pet-heart"

		/**
		The guess of the visitor in the game of Glitter: `left` or `right`.
		*/
		case petGuess = "data-pet-guess"

		/**
		How grown up Glitter is, on her screen: `baby`, `teen`, `grown-up`, or `legend`.
		*/
		case petStage = "data-pet-stage"

		case butlerForm = "geocities-butler-form"
		case butlerQuestion = "geocities-butler-question"
		case butlerAnswer = "geocities-butler-answer"

		case fact = "geocities-fact"
		case nextFact = "geocities-next-fact"

		case pollForm = "geocities-poll-form"
		case pollStatus = "geocities-poll-status"
		case pollResults = "geocities-poll-results"

		/**
		The made-up votes of an option of the poll.
		*/
		case votes = "data-votes"

		case counter = "geocities-counter"
		case guestbookForm = "geocities-guestbook-form"
		case guestbookStatus = "geocities-guestbook-status"
		case guestbookEntries = "geocities-guestbook-entries"
		case entryTemplate = "geocities-entry"

		/**
		A field of a guestbook entry, like `name` or `message`.
		*/
		case field = "data-field"

		case secret = "geocities-secret"
		case paradeTemplate = "geocities-parade"

		/**
		The effect of a big red button that is on now, on the panel: `spin` spins the GIFs, and `rainbow` turns the colors of the page.
		*/
		case effect = "data-effect"

		case root = "geocities-root"
		case toast = "geocities-toast"
		case loadTime = "geocities-load-time"
		case bookmark = "geocities-bookmark"

		case bannerStar = "geocities-banner-star"
		case bannerStatus = "geocities-banner-status"

		case quizPrize = "geocities-quiz-prize"
		case quizQuestion = "geocities-quiz-question"
		case quizAnswers = "geocities-quiz-answers"
		case quizLifelines = "geocities-quiz-lifelines"
		case quizStatus = "geocities-quiz-status"
		case quizStart = "geocities-quiz-start"

		/**
		The index of an answer of the quiz, from 0 to 3.
		*/
		case quizAnswer = "data-quiz-answer"

		/**
		A lifeline of the quiz: `fifty`, `phone`, or `audience`.
		*/
		case quizLifeline = "data-quiz-lifeline"

		case reportBrowser = "geocities-report-browser"
		case reportSystem = "geocities-report-system"
		case reportScreen = "geocities-report-screen"
		case reportColors = "geocities-report-colors"
		case reportOnline = "geocities-report-online"
		case reportBill = "geocities-report-bill"

		/**
		The pill of the Matrix: `red` or `blue`.
		*/
		case pill = "data-pill"

		case matrixStatus = "geocities-matrix-status"
		case matrixTemplate = "geocities-matrix"

		/**
		The file that a download button downloads, like `sindre.scr`.
		*/
		case download = "data-download"

		case downloadWindow = "geocities-download"
		case downloadTitle = "geocities-download-title"
		case downloadText = "geocities-download-text"
		case downloadBar = "geocities-download-bar"
		case downloadTime = "geocities-download-time"
		case downloadCancel = "geocities-download-cancel"

		case wallpaper = "geocities-wallpaper"
		case saverWait = "geocities-saver-wait"
		case saverPreview = "geocities-saver-preview"
		case saverTemplate = "geocities-saver"
		case snow = "geocities-snow"
		case snowTemplate = "geocities-snowflake"
		case titleScroll = "geocities-title-scroll"

		case newMail = "geocities-new-mail"
		case newMailText = "geocities-new-mail-text"
		case newMailClose = "geocities-new-mail-close"

		case bannerPrint = "geocities-banner-print"
		case certificate = "geocities-certificate"
		case certificateText = "geocities-certificate-text"

		/**
		The bars of the jukebox, which bounce while it plays.
		*/
		case spectrum = "geocities-spectrum"

		case lake = "geocities-lake"
		case lakeLoading = "geocities-lake-loading"
		case lakeBar = "geocities-lake-bar"
		case lakeCanvas = "geocities-lake-canvas"
		case lakeStatus = "geocities-lake-status"

		/**
		The number of a picture of SindreCam, from 0.
		*/
		case camScene = "data-cam-scene"

		case camStatic = "geocities-cam-static"
		case camTime = "geocities-cam-time"
		case camCountdown = "geocities-cam-countdown"
		case camRefresh = "geocities-cam-refresh"

		case weatherCheck = "geocities-weather-check"
		case weatherStatus = "geocities-weather-status"

		case icqLight = "geocities-icq-light"
		case icqStatus = "geocities-icq-status"
		case icqMessage = "geocities-icq-message"
		case icqReply = "geocities-icq-reply"
		case mood = "geocities-mood"

		case candleLight = "geocities-candle-light"
		case candleStatus = "geocities-candle-status"

		/**
		What a button of Rocky does: `feed`, `pet`, `walk`, or `trick`.
		*/
		case rockAction = "data-rock-action"

		case rockStatus = "geocities-rock-status"
		case fortuneText = "geocities-fortune-text"
		case fortuneCrack = "geocities-fortune-crack"

		case fameScore = "geocities-fame-score"
		case fameVisits = "geocities-fame-visits"
		case fameCare = "geocities-fame-care"
		case skull = "geocities-skull"

		case helper = "geocities-helper"
		case helperText = "geocities-helper-text"

		/**
		The answer of the visitor to the helper of the guestbook: `yes`, `no`, or `never`.
		*/
		case helperAnswer = "data-helper-answer"

		case panel = "geocities-panel"

		case snakePhone = "geocities-snake-phone"
		case snakeScore = "geocities-snake-score"
		case snakeScreen = "geocities-snake-screen"
		case snakeStatus = "geocities-snake-status"

		/**
		A key of the phone of Snake, like `2`, `*`, or `#`.
		*/
		case snakeKey = "data-snake-key"

		case desktop = "geocities-desktop"

		/**
		The window that a desktop icon or an item of the Start menu opens, like `paint`.
		*/
		case desktopOpen = "data-desktop-open"

		/**
		A window of the desktop, by the name of its program, like `paint`.
		*/
		case desktopWindow = "data-desktop-window"

		/**
		The title bar of a window of the desktop, which drags the window.
		*/
		case desktopTitleBar = "data-desktop-title-bar"

		/**
		The close button of a window of the desktop.
		*/
		case desktopClose = "data-desktop-close"

		case startMenu = "geocities-start-menu"
		case startButton = "geocities-start-button"
		case taskbarClock = "geocities-taskbar-clock"
		case shutDown = "geocities-shut-down"
		case shutDownTemplate = "geocities-shut-down-screen"

		/**
		A tool of Unicorn Paint, like `pencil` or `stamp`.
		*/
		case paintTool = "data-paint-tool"

		/**
		The picture that a stamp of Unicorn Paint stamps.
		*/
		case paintStamp = "data-paint-stamp"

		/**
		A color of the palette of Unicorn Paint, like `#ff0000`.
		*/
		case paintColor = "data-paint-color"

		case paintStamps = "geocities-paint-stamps"
		case paintUndo = "geocities-paint-undo"
		case paintClear = "geocities-paint-clear"
		case paintSave = "geocities-paint-save"
		case paintCanvas = "geocities-paint-canvas"
		case paintCursor = "geocities-paint-cursor"
		case paintStatus = "geocities-paint-status"

		case sweeperBugs = "geocities-sweeper-bugs"
		case sweeperFace = "geocities-sweeper-face"
		case sweeperTime = "geocities-sweeper-time"
		case sweeperGrid = "geocities-sweeper-grid"
		case sweeperFlag = "geocities-sweeper-flag"
		case sweeperStatus = "geocities-sweeper-status"

		/**
		The number of a square of Y2K Bugsweeper, from 0 at the top left.
		*/
		case sweeperCell = "data-sweeper-cell"

		/**
		The number of bugs that touch an open square of Y2K Bugsweeper, from 1 to 8, which gives the number its color.
		*/
		case sweeperCount = "data-sweeper-count"

		case diaryLock = "geocities-diary-lock"
		case diaryPassword = "geocities-diary-password"
		case diaryHint = "geocities-diary-hint"
		case diaryStatus = "geocities-diary-status"
		case diaryText = "geocities-diary-text"

		/**
		A pile of Solitaire, which the cards of the win jump off.
		*/
		case solitairePile = "data-solitaire-pile"

		case solitaireWin = "geocities-solitaire-win"
		case solitaireStatus = "geocities-solitaire-status"

		case defrag = "geocities-defrag"
		case defragStart = "geocities-defrag-start"
		case defragStatus = "geocities-defrag-status"

		/**
		A block of the hard drive in the defragmenter, by its number.
		*/
		case defragBlock = "data-defrag-block"

		case recycleList = "geocities-recycle-list"
		case recycleEmpty = "geocities-recycle-empty"
		case recycleStatus = "geocities-recycle-status"

		case blueScreenTemplate = "geocities-blue-screen"
		case bombTemplate = "geocities-bomb"
		case effectTemplate = "geocities-effect"
		case trailDotTemplate = "geocities-trail-dot"
		case saverCanvasTemplate = "geocities-saver-canvas"

		case partyStart = "geocities-party-start"
		case partyCount = "geocities-party-count"
		case partyStatus = "geocities-party-status"

		case saverKind = "geocities-saver-kind"
		case saverMonitor = "geocities-saver-monitor"
		case trailKind = "geocities-trail-kind"
	}
}
