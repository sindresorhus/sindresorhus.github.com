import Elementary
import Foundation
import SiteKit

extension GeoCitiesPage {
	/**
	The 88×31 buttons at the end of the page, with the text on each.
	*/
	static let buttons: [(gif: GIF, text: String)] = [
		(.buttonBestViewedNetscape, "This page is best viewed with Netscape Now! 3.0"),
		(.buttonNetscapeNow, "Netscape Now!"),
		(.buttonMadeWithNotepad, "Built with Microsoft Notepad"),
		(.buttonNotepadNow, "Notepad Now!"),
		(.buttonMadeWithMac, "Made with a Mac"),
		(.buttonMacOS8, "Mac OS 8: Get it now!"),
		(.buttonIMac, "I love iMac"),
		(.buttonAnyBrowser, "Any Browser"),
		(.button800x600, "Best viewed at 800 × 600"),
		(.buttonNoFrames, "No frames now!"),
		(.buttonHTMLNow, "Learn HTML now!"),
		(.buttonY2K, "Year 2000 compliant"),
		(.buttonGeoCities, "GeoCities"),
		(.buttonGuestbook, "The Guestbook: free"),
		(.buttonICQ, "Download ICQ"),
		(.buttonWinamp, "Nullsoft Winamp"),
		(.buttonQuickTime, "Get QuickTime"),
		(.buttonMIDI, "MIDI files now!"),
		(.buttonMSPaint, "Long live MSPaint!"),
		(.buttonHandPainted, "Hand-painted"),
		(.buttonVim, "This site is vim powered"),
		(.buttonCoffee, "Fueled by coffee"),
		(.buttonCopyFloppy, "Copy that floppy!"),
		(.buttonBandwidth, "Bandwidth Conservation Society"),
		(.buttonNetscapeIE, "Best viewed with Netscape 4 or Internet Explorer 4"),
		(.buttonOpera, "Opera: the free browser"),
		(.buttonSimpleText, "Made with HTML hardcore in SimpleText"),
		(.buttonLoveMac, "We love Mac"),
		(.buttonMIDINote, "MIDI music"),
		(.buttonArea51, "GeoCities Area 51"),
	]

	/**
	The number of holes of the game, three rows of three, like the number keys 1 to 9 of a phone.
	*/
	static let holeCount = 9

	/**
	The facts about me in the about section.
	*/
	static let aboutMeFacts: [(label: String, value: String)] = [
		("Computer", "iMac in Bondi Blue"),
		("Speed", "233 MHz and 32 MB of RAM (very fast)"),
		("Hard drive", "4 GB. I will never fill it up."),
		("Modem", "56k, when nobody is on the phone"),
		("Browser", "Netscape Navigator 4.7"),
		("HTML editor", "FrontPage Express. I write all my HTML by hand!"),
		("Favorite animal", "Unicorns. They are real. I saw one on a screen saver."),
		("Favorite food", "Waffles with brown cheese"),
		("Indentation", "Tabs, of course"),
	]

	/**
	The tunes of the MIDI jukebox, which are in the public domain. Each note is a MIDI note number and its length in beats, and a note of 0 is a rest.
	*/
	static let tunes = [
		Tune(
			file: "mountain_king.mid",
			title: "In the Hall of the Mountain King, Edvard Grieg",
			tempo: 132,
			speedUp: 1.15,
			notes: [
				[59, 0.5], [61, 0.5], [62, 0.5], [64, 0.5], [66, 0.5], [62, 0.5], [66, 1],
				[65, 0.5], [61, 0.5], [65, 1], [64, 0.5], [60, 0.5], [64, 1],
				[59, 0.5], [61, 0.5], [62, 0.5], [64, 0.5], [66, 0.5], [62, 0.5], [66, 0.5], [71, 0.5],
				[69, 0.5], [66, 0.5], [62, 0.5], [66, 0.5], [69, 2],
			]
		),
		Tune(
			file: "morning_mood.mid",
			title: "Morning Mood, Edvard Grieg",
			tempo: 96,
			speedUp: 1,
			notes: [
				[71, 0.5], [68, 0.5], [66, 0.5], [64, 0.5], [66, 0.5], [68, 1.5],
				[71, 0.5], [68, 0.5], [66, 0.5], [64, 0.5], [66, 0.5], [68, 0.5], [66, 0.5], [68, 0.5],
				[71, 0.5], [68, 0.5], [71, 0.5], [73, 0.5], [68, 0.5], [73, 0.5],
				[71, 0.5], [68, 0.5], [66, 0.5], [64, 1.5], [0, 1],
			]
		),
		Tune(
			file: "ode_to_joy.mid",
			title: "Ode to Joy, Ludwig van Beethoven",
			tempo: 144,
			speedUp: 1,
			notes: [
				[64, 1], [64, 1], [65, 1], [67, 1], [67, 1], [65, 1], [64, 1], [62, 1],
				[60, 1], [60, 1], [62, 1], [64, 1], [64, 1.5], [62, 0.5], [62, 2],
				[64, 1], [64, 1], [65, 1], [67, 1], [67, 1], [65, 1], [64, 1], [62, 1],
				[60, 1], [60, 1], [62, 1], [64, 1], [62, 1.5], [60, 0.5], [60, 2],
			]
		),
	]

	/**
	The fun facts, which `geocities.js` picks from. The first one is on the page without scripts.
	*/
	static let funFacts = [
		"Opera, the web browser, is made in Norway! It started at Telenor, the Norwegian phone company, in 1994.",
		"The cheese slicer was invented in Norway in 1925, by Thor Bjørklund. Perfect for brown cheese!",
		"The unicorn is the national animal of Scotland. Good choice, Scotland.",
		"The first webcam watched a coffee pot at the University of Cambridge, so people could see if there was coffee before they walked over.",
		"Tamagotchi means something like “egg watch” in Japanese.",
		"The Hampster Dance page has only four different GIFs, and millions of people have visited it.",
		"Some computers save the year with only two digits. After 99 comes 00, and they think it is 1900 again. That is the Y2K bug!",
		"In the north of Norway, the sun does not set for weeks in the summer. Perfect for coding all night!",
		"The first web page went online in 1991. It had no GIFs at all. Can you imagine?",
		"Norway has more than 1,000 fjords. I have not counted them myself yet.",
		"Some people say that a group of unicorns is called a blessing.",
		"Ctrl+Z is undo. Ctrl+Y is redo. Ctrl+Alt+Delete is panic.",
	]

	/**
	The options of the poll, with made-up votes.
	*/
	static let pollOptions: [(name: String, votes: Int)] = [
		("Netscape Navigator 4.7", 412),
		("Internet Explorer 5", 398),
		("Opera 3.6 (from Norway!)", 157),
		("Lynx (text only, very fast)", 23),
		("NCSA Mosaic (I like it retro)", 9),
		("What is a browser?", 64),
	]

	/**
	The awards of the page, with a note about each.
	*/
	static let awards: [(title: String, note: String)] = [
		("Cool Site of the Day", "From my mom. Every day."),
		("Top 5% of the Web", "I did the math myself."),
		("Golden Unicorn Award", "For excellence in HTML. I made this one."),
		("Best Use of <blink>", "Nominated by me."),
		("Featured on Yahoo!", "Soon! I have submitted my page 14 times."),
		("Y2K Compliant", "Probably."),
	]

	/**
	The favorite links of 1999. Most of those pages are gone, so most links go to Wikipedia.
	*/
	static let topLinks: [(title: String, url: URL, note: String)] = [
		("The Space Jam web site", #URL("https://www.spacejam.com/1996/"), "still online since 1996!"),
		("The Hampster Dance", #URL("https://en.wikipedia.org/wiki/Hampster_Dance"), "dance the night away"),
		("The Dancing Baby", #URL("https://en.wikipedia.org/wiki/Dancing_baby"), "ooga chaka!"),
		("Tamagotchi", #URL("https://en.wikipedia.org/wiki/Tamagotchi"), "I miss my first three"),
		("Opera", #URL("https://en.wikipedia.org/wiki/Opera_(web_browser)"), "a browser from Norway!"),
		("WebRing", #URL("https://en.wikipedia.org/wiki/Webring"), "next site, please"),
		("Cool Site of the Day", #URL("https://en.wikipedia.org/wiki/Cool_Site_of_the_Day"), "pick my page!"),
		("GeoCities", #URL("https://en.wikipedia.org/wiki/GeoCities"), "my landlord"),
		("Ask Jeeves", #URL("https://en.wikipedia.org/wiki/Ask.com"), "he knows everything"),
		("Winamp", #URL("https://en.wikipedia.org/wiki/Winamp"), "the best MP3 player"),
	]

	/**
	The entries of the guestbook from 1999, written like the real ones of that time: typos, lowercase, too many exclamation marks, and a request to sign their guestbook back.
	*/
	static let guestbookEntries = [
		GuestbookEntry(name: "Jessica", place: "Ohio, USA", date: "12/30/1999", via: "Yahoo!", message: "hi!! i found ur page when i was looking for unicorn pictures. i saved the rainbow one for my desktop, hope thats ok :) please visit my page too, it has a backstreet boys section"),
		GuestbookEntry(name: "Trond", place: "Trondheim, Norway", date: "12/27/1999", via: "A friend", message: "Hei Sindre! Kul side. The alien game is very hard on my trackball. Godt nytt år!"),
		GuestbookEntry(name: "mamma", place: "hjemme", date: "12/24/1999", via: "My son told me", message: "Hei det er mamma. Er det her jeg skal skrive? Veldig fin side. Middagen er klar om 10 min. Klem fra mamma"),
		GuestbookEntry(name: "DarkAngel", place: "Somewhere in Texas", date: "12/12/1999", via: "A webring", message: "cool site!!! how did u get the flames to move?? i have been trying for 3 days. sign my guestbook back plz!!!"),
		GuestbookEntry(name: "Kristin", place: "Bergen", date: "11/30/1999", via: "AltaVista", message: "Your page took 4 minutes to load on our modem but it was worth it. The MIDI is stuck in my head now."),
		GuestbookEntry(name: "Webmaster of The Pixel Palace", place: "GeoCities, Hollywood", date: "10/15/1999", via: "A webring", message: "Nice page. Your counter is broken, it says 1999 every time. Want to exchange 88x31 buttons?"),
	]

	/**
	A unicorn in ASCII art.
	*/
	static let asciiUnicorn = #"""
	                    ,
	                   /|
	                  / |
	                 /  /
	      ,,,,,,,   /  /
	    ((((((((( _/  /`-.
	   (((((((((  /  o    `-.
	  (((((((((  |           `.
	  ((((((((   |    ___      )
	  (((((((    |   /   `----'
	  ((((((     |  |
	   ((((      |  |
	    ((       |  |
	"""#

	/**
	A waffle in ASCII art, in the shape of a heart, like the waffles of Norway.
	*/
	static let asciiWaffle = ##"""
	   .-"""-.   .-"""-.
	  /#|#|#|#\ /#|#|#|#\
	 |#|#|#|#|#V#|#|#|#|#|
	 |#|#|#|#|#|#|#|#|#|#|
	  \#|#|#|#|#|#|#|#|#/
	    \#|#|#|#|#|#|#/
	      \#|#|#|#|#/
	        \#|#|#/
	          \#/
	"""##

	/**
	The buttons of the site map, like the navigation frame of a home page from 1999, with the ID of the part that each one jumps to.
	*/
	static let siteMapItems: [(gif: GIF, title: String, anchor: String)] = [
		(.navHome, "Home", Hooks.welcome.rawValue),
		(.musicNotes, "Jukebox", "geocities-jukebox"),
		(.buttonAmigaDemo, "Demos", "geocities-cracktro"),
		(.newStuff, "New Stuff", "geocities-java"),
		(.cat, "My Pets", GeoCitiesPets.Hooks.root.rawValue),
		(.pacman, "Games", "geocities-games"),
		(.mobilePhone, "Snake", "geocities-snake"),
		(.skiSlope, "Winter Games", GeoCitiesWinterGames.rootID),
		(.heart, "Glitter", "geocities-glitter"),
		(.question, "Quiz", "geocities-quiz"),
		(.computerGame, "Arcade", "geocities-arcade"),
		(.turnBook, "Adventures", GeoCitiesAdventure.rootID),
		(.computerSmall, "My PC", "geocities-pc"),
		(.buttonMacVsWindows, "My iMac", GeoCitiesMacOS.Hooks.root.rawValue),
		(.iMac, "My Room", GeoCitiesRoom.rootID),
		(.hotSites, "Cool Links", "geocities-links"),
		(.candle, "Shrine", "geocities-shrine"),
		(.speakerNotes, "Music Room", GeoCitiesMusicRoom.Hooks.root.rawValue),
		(.signGuestbook, "Guestbook", "geocities-guestbook"),
		(.mailbox, "WaffleMail", GeoCitiesInbox.rootID),
		(.computerGame, "Make a Page", GeoCitiesPageMaker.rootID),
		(.floppy, "Downloads", "geocities-downloads"),
		(.envelope, "E-mail Me", "geocities-mail"),
	]

	/**
	The news of the page, newest first, for the ticker that scrolls up.
	*/
	static let news: [(date: String, text: String)] = [
		("12/31/1999", "Added a Java applet! It takes forever to load, but it works."),
		("12/30/1999", "SindreCam is live! Most of the time."),
		("12/28/1999", "Glitter learned the moonwalk."),
		("12/24/1999", "My mom signed my guestbook. Hi mamma!"),
		("12/20/1999", "50 new GIFs! My page is 2 MB now."),
		("12/15/1999", "I built a shrine to waffles. It was about time."),
		("12/01/1999", "I adopted Rocky, my pet rock. He is doing great."),
	]

	/**
	The pictures of SindreCam, which `geocities.js` shows one after the other, with a new one every 30 seconds.
	*/
	static let camScenes: [(gif: GIF, caption: String)] = [
		(.kidComputer, "Me, coding. Do not disturb!"),
		(.storm, "The view from my window. Bergen, of course."),
		(.cat, "The cat of the neighbors. We do not have a cat."),
		(.toaster, "Making waffles. OK, it is a toaster. The waffle iron is broken."),
		(.waggingDog, "The dog of my best friend. He wants to be on the Internet too."),
	]

	/**
	The weather in Bergen this week.
	*/
	static let forecast: [(day: String, weather: String)] = [
		("Monday", "Rain"),
		("Tuesday", "Rain"),
		("Wednesday", "Heavy rain"),
		("Thursday", "Rain, sideways"),
		("Friday", "Drizzle (that is rain too)"),
		("Saturday", "Rain"),
		("Sunday", "Sunny! Just kidding. Rain."),
	]

	/**
	The made-up visits of the page in each month of 1999, which add up to 1999, like the visitor counter.
	*/
	static let hits: [(month: String, count: Int)] = [
		("Jan", 75),
		("Feb", 57),
		("Mar", 195),
		("Apr", 113),
		("May", 138),
		("Jun", 44),
		("Jul", 25),
		("Aug", 94),
		("Sep", 170),
		("Oct", 207),
		("Nov", 258),
		("Dec", 623),
	]

	/**
	Why waffles deserve a shrine.
	*/
	static let waffleReasons = [
		"They are shaped like hearts. In Norway, at least.",
		"Brown cheese on a warm waffle. Need I say more?",
		"You can eat them for breakfast, lunch, dinner, and in between.",
		"Grandma makes the best ones. Sorry, mamma.",
		"Glitter loves them too, and she is a unicorn, so she knows.",
	]

	/**
	The keys of the mobile phone of Snake, with what each says to screen readers, and the arrow on the keys that steer.
	*/
	static let phoneKeys: [(key: String, name: String, symbol: String?)] = [
		("1", "1", nil),
		("2", "2, up", "▲"),
		("3", "3", nil),
		("4", "4, left", "◀"),
		("5", "5, start or pause", "OK"),
		("6", "6, right", "▶"),
		("7", "7", nil),
		("8", "8, down", "▼"),
		("9", "9", nil),
		("*", "* (star)", nil),
		("0", "0", nil),
		("#", "# (pound)", nil),
	]

	/**
	The programs of the desktop, with the ID of the window that each opens, and its icon.
	*/
	static let desktopApps: [(id: String, title: String, icon: String)] = [
		("paint", "Unicorn Paint", "🎨"),
		("sweeper", "Y2K Bugsweeper", "🐛"),
		("notepad", "SECRET.TXT", "📝"),
		("solitaire", "Solitaire", "🃏"),
		("computer", "My Computer", "🖥️"),
		("recycle", "Recycle Bin", "🗑️"),
		("documents", "My Documents", "📁"),
		("ie", "Internet Explorer", "🌐"),
		("network", "Network Neighborhood", "🏘️"),
		("control", "Control Panel", "🎛️"),
		("calc", "Calculator", "🧮"),
		("dos", "MS-DOS Prompt", "⬛"),
		("freecell", "FreeCell", "♠️"),
		("wordpad", "LETTER TO SANTA 2000.DOC", "📄"),
		("fixer", "Y2K FIX.EXE", "🩹"),
		("pinball", "3D Pinball", "🚀"),
		("hearts", "Hearts", "♥️"),
		("cdrom", "Windows 95 CD (D:)", "💿"),
		("bonzi", "BonziBUDDY", "🦍"),
		("bob", "Microsoft Bob", "🤓"),
		("happy", "Happy99.exe", "🎆"),
	]

	/**
	The tools of Unicorn Paint that draw, with what each is called.
	*/
	static let paintTools: [(id: String, name: String, icon: String)] = [
		("pencil", "Pencil", "✏️"),
		("brush", "Brush", "🖌️"),
		("spray", "Spray can", "💨"),
		("fill", "Fill with color", "🪣"),
		("rainbow", "Rainbow brush", "🌈"),
		("stamp", "Stamp", "🦄"),
		("eraser", "Eraser", "🧽"),
	]

	/**
	The stamps of Unicorn Paint, which stamp the still frames of the GIFs of the page.
	*/
	static let paintStamps: [(gif: GIF, name: String)] = [
		(.unicorn, "Unicorn"),
		(.goldStar, "Star"),
		(.heart, "Heart"),
		(.alien, "Alien"),
		(.ufo, "Flying saucer"),
		(.rainbow, "Rainbow"),
		(.flyingPig, "Flying pig"),
		(.dolphin, "Dolphin"),
	]

	/**
	The 16 colors of Windows, like in the palette of Paint.
	*/
	static let paintColors: [(hex: String, name: String)] = [
		("#000000", "Black"),
		("#808080", "Gray"),
		("#800000", "Maroon"),
		("#808000", "Olive"),
		("#008000", "Green"),
		("#008080", "Teal"),
		("#000080", "Navy"),
		("#800080", "Purple"),
		("#ffffff", "White"),
		("#c0c0c0", "Silver"),
		("#ff0000", "Red"),
		("#ffff00", "Yellow"),
		("#00ff00", "Lime"),
		("#00ffff", "Aqua"),
		("#0000ff", "Blue"),
		("#ff00ff", "Fuchsia"),
	]

	/**
	The number of squares on each side of Y2K Bugsweeper, like the beginner level of Minesweeper.
	*/
	static let sweeperSize = 9

	/**
	The number of blocks of the hard drive in the defragmenter.
	*/
	static let defragBlockCount = 120

	/**
	The files in the Recycle Bin, with why I deleted each.
	*/
	static let recycledFiles: [(file: String, note: String)] = [
		("canyon.mid", "it did not fit in my 2 MB of web space"),
		("spaces.txt", "I only use tabs"),
		("homework_math.doc", "oops"),
		("my_page_with_frames.html", "mamma says frames are bad for you"),
		("letter_to_santa.txt", "too late, it is December 31"),
	]

	/**
	My secret diary in Notepad.
	*/
	static let diary = """
	DEAR DIARY. TOP SECRET!!! If you are my little sister, stop reading NOW.

	12/03/1999
	I learned the <blink> tag today. My page is so much better now. Mamma says it gives her a headache. She does not understand art.

	12/09/1999
	Trond says spaces are better than tabs. We are no longer friends.

	12/10/1999
	Trond and I are friends again. He still uses spaces. I am working on him.

	12/14/1999
	2 new visitors today! One was me at school. The other one was also me, at the library.

	12/20/1999
	I filled the bathtub with water for Y2K, just in case. Mamma made me empty it. If the world ends, it is her fault.

	12/24/1999
	I got a Furby for Christmas. It talks all night. It is under my bed now, with a sock on it.

	12/28/1999
	Glitter learned the moonwalk. I am so proud of her.

	12/31/1999
	Last entry of the millennium! If all computers stop at midnight, this diary is my legacy. Please give my GIFs to a good home.
	"""
}

extension GeoCitiesPage {
	/**
	An entry of the guestbook. Each field has a `data-field` hook, so `geocities.js` can fill a copy of an empty entry.
	*/
	struct GuestbookEntry: HTML {
		let name: String
		let place: String
		let date: String
		let via: String
		let message: String

		var body: some HTML {
			li {
				field("name", label: "Name", value: name)
				field("place", label: "From", value: place)
				field("date", label: "Date", value: date)
				field("via", label: "Found me via", value: via)
				field("message", label: "Comments", value: message)
			}
			.style(Styles.entry)
		}

		private func field(_ field: String, label: String, value: String) -> some HTML {
			p {
				strong {
					"\(label): "
				}

				span(.hook(Hooks.field, value: field)) {
					value
				}
			}
		}
	}

	/**
	A tune of the MIDI jukebox.
	*/
	struct Tune: Encodable {
		let file: String
		let title: String

		/**
		The beats per minute.
		*/
		let tempo: Int

		/**
		How much faster the tune plays each time it repeats, like 1.1 for 10% faster, or 1 for the same speed.
		*/
		let speedUp: Double

		/**
		Each note as a MIDI note number and its length in beats. A note of 0 is a rest.
		*/
		let notes: [[Double]]
	}

	/**
	The data that `geocities.js` reads from the page.
	*/
	struct ScriptData: Encodable {
		let facts: [String]
		let tunes: [Tune]
		let quiz: [QuizQuestion]
	}

	/**
	A question of Who Wants to Be a Unicornaire?, with the index of the right answer.
	*/
	struct QuizQuestion: Encodable {
		let prize: String
		let question: String
		let answers: [String]
		let correct: Int
	}
}
