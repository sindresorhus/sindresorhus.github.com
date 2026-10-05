import Elementary
import Foundation
import SiteKit

extension GeoCitiesPage {
	/**
	The animated GIFs of the page, from collections of the late 1990s: GIFs that GeoCities pages used, saved from GeoCities by Archive Team, the AnimatedGif.net library, the AnimatedImages.org library, and a collection of 88×31 buttons, plus an 88×31 button of my own. They are in `public/1999`, with the source of each above it. A GIF that moves has a still frame in `public/1999/still`, for visitors who prefer reduced motion.
	*/
	enum GIF: String, CaseIterable {
		// https://cyber.dabamos.de/88x31/games.gif
		case buttonGames = "button-games"
		// https://cyber.dabamos.de/88x31/get_java.gif
		case buttonGetJava = "button-get-java"
		// https://cyber.dabamos.de/88x31/shockwave.gif
		case buttonGetShockwave = "button-get-shockwave"
		// https://cyber.dabamos.de/88x31/join_shockrave.gif
		case buttonShockRave = "button-shockrave"
		// https://cyber.dabamos.de/88x31/spaceinvaders.gif
		case buttonSpaceInvaders = "button-space-invaders"
		// http://www.animatedgif.net/games/dice2_e0.gif
		case dice
		// http://www.animatedgif.net/games/gamecube_e0.gif
		case gamesCube = "games-cube"
		// http://www.animatedgif.net/space/alien8_e0.gif
		case alien
		// https://cyber.dabamos.de/88x31/apple_fatal_error.gif
		case buttonMacVsWindows = "button-mac-vs-windows"
		// https://cyber.dabamos.de/88x31/amigademo.gif
		case buttonAmigaDemo = "button-amiga-demo"
		// https://cyber.dabamos.de/88x31/amiga_power.gif
		case buttonAmigaPower = "button-amiga-power"
		// https://cyber.dabamos.de/88x31/modplug.gif
		case buttonModPlug = "button-modplug"
		// https://cyber.dabamos.de/88x31/modulez.gif
		case buttonModulez = "button-modulez"
		// https://cyber.dabamos.de/88x31/sceneorg.gif
		case buttonSceneOrg = "button-scene-org"
		// https://cyber.dabamos.de/88x31/dos.gif
		case buttonDOS = "button-dos"
		// http://www.animatedgif.net/fireexplosions/bomb2_e0.gif
		case bomb
		// http://www.animatedgif.net/animals/bugs/butterflygroup_e0.gif
		case butterflies
		// https://cyber.dabamos.de/88x31/800x600.gif
		case button800x600 = "button-800x600"
		// https://cyber.dabamos.de/88x31/anybrowser2.gif
		case buttonAnyBrowser = "button-any-browser"
		// https://cyber.dabamos.de/88x31/geocities_area_51.gif
		case buttonArea51 = "button-area-51"
		// https://cyber.dabamos.de/88x31/bandwith_conservation_society.gif
		case buttonBandwidth = "button-bandwidth"
		// https://cyber.dabamos.de/88x31/best_ns.gif
		case buttonBestViewedNetscape = "button-best-viewed-netscape"
		// https://cyber.dabamos.de/88x31/coffee.gif
		case buttonCoffee = "button-coffee"
		// https://cyber.dabamos.de/88x31/copy_floppy.gif
		case buttonCopyFloppy = "button-copy-floppy"
		// https://cyber.dabamos.de/88x31/geocities.gif
		case buttonGeoCities = "button-geocities"
		// https://cyber.dabamos.de/88x31/guestbook.gif
		case buttonGuestbook = "button-guestbook"
		// https://cyber.dabamos.de/88x31/handpainted.gif
		case buttonHandPainted = "button-hand-painted"
		// https://cyber.dabamos.de/88x31/html.gif
		case buttonHTMLNow = "button-html-now"
		// https://cyber.dabamos.de/88x31/icq.gif
		case buttonICQ = "button-icq"
		// https://cyber.dabamos.de/88x31/imac.gif
		case buttonIMac = "button-imac"
		// https://cyber.dabamos.de/88x31/lovemac.gif
		case buttonLoveMac = "button-love-mac"
		// https://cyber.dabamos.de/88x31/macos8.gif
		case buttonMacOS8 = "button-mac-os-8"
		// https://cyber.dabamos.de/88x31/madewithamac.gif
		case buttonMadeWithMac = "button-made-with-mac"
		// https://cyber.dabamos.de/88x31/built_with_microsoft_notepad.gif
		case buttonMadeWithNotepad = "button-made-with-notepad"
		// https://cyber.dabamos.de/88x31/midi_files_now.gif
		case buttonMIDI = "button-midi"
		// https://cyber.dabamos.de/88x31/midinote.gif
		case buttonMIDINote = "button-midi-note"
		// https://cyber.dabamos.de/88x31/mspaint.gif
		case buttonMSPaint = "button-mspaint"
		// https://cyber.dabamos.de/88x31/ns4ie4.gif
		case buttonNetscapeIE = "button-netscape-ie"
		// https://cyber.dabamos.de/88x31/netscape_now.gif
		case buttonNetscapeNow = "button-netscape-now"
		// https://cyber.dabamos.de/88x31/noframes.gif
		case buttonNoFrames = "button-no-frames"
		// https://cyber.dabamos.de/88x31/notepad3.gif
		case buttonNotepadNow = "button-notepad-now"
		// https://cyber.dabamos.de/88x31/opera.gif
		case buttonOpera = "button-opera"
		// https://cyber.dabamos.de/88x31/quicktime.gif
		case buttonQuickTime = "button-quicktime"
		// https://cyber.dabamos.de/88x31/simpletext.gif
		case buttonSimpleText = "button-simpletext"
		// Made for this page with ImageMagick, in Geneva, a font of the classic Mac OS.
		case buttonSindre = "button-sindre"
		// https://cyber.dabamos.de/88x31/vim.gif
		case buttonVim = "button-vim"
		// https://cyber.dabamos.de/88x31/winamp.gif
		case buttonWinamp = "button-winamp"
		// https://cyber.dabamos.de/88x31/y2k2.gif
		case buttonY2K = "button-y2k"
		// http://www.animatedgif.net/miscellaneous/camramn_e0.gif
		case cameraman
		// http://www.animatedgif.net/fireexplosions/candle2_e0.gif
		case candle
		// http://www.animatedgif.net/fireexplosions/animatedcandle_e0.gif
		case candleSmall = "candle-small"
		// http://www.animatedgif.net/fireexplosions/pkcandle_e0.gif
		case candleTall = "candle-tall"
		// http://www.animatedgif.net/animals/cats/catrun_e0.gif
		case cat
		// http://www.animatedgif.net/bookscalendars/book_candle_e0.gif
		case bookCandle = "book-candle"
		// http://www.animatedgif.net/bookscalendars/turnbook_e0.gif
		case turnBook = "turn-book"
		// https://raw.githubusercontent.com/adryd325/oneko.js/main/oneko.gif (the sprites of Neko, which its author made public domain)
		case neko
		// http://www.animatedgif.net/animals/bugs/ahwormmove_e0.gif
		case worm
		// http://www.animatedgif.net/seasonal/newyears/kkpopcork_e0.gif
		case champagne
		// http://www.animatedgif.net/sitemessages/misc/comeback_e0.gif
		case comeBack = "come-back"
		// http://www.animatedgif.net/underconstruction/comsoon1_e0.gif
		case comingSoon = "coming-soon"
		// http://www.animatedgif.net/computers/computer-4_e0.gif
		case computerGame = "computer-game"
		// http://www.animatedgif.net/computers/computer_2_e0.gif
		case computerSmall = "computer-small"
		// http://www.animatedgif.net/underconstruction/constzone_e0.gif
		case constructionBarrier = "construction-barrier"
		// http://www.animatedgif.net/underconstruction/jackhammer_e0.gif
		case constructionJackhammer = "construction-jackhammer"
		// http://www.animatedgif.net/underconstruction/digmove1_e0.gif
		case constructionPage = "construction-page"
		// http://www.animatedgif.net/underconstruction/anim0206-1_e0.gif
		case constructionWorker = "construction-worker"
		// http://www.animatedgif.net/miscellaneous/coolspin_e0.gif
		case cool
		// http://www.animatedgif.net/animals/otheranimals/coolcow_e0.gif
		case coolCow = "cool-cow"
		// http://www.animatedgif.net/miscellaneous/anisun_e0.gif
		case coolSun = "cool-sun"
		// http://www.animatedgif.net/clockscounters/ag_count_e0.gif
		case counterDigits = "counter-digits"
		// http://www.animatedgif.net/bookscalendars/quill_on_book_e0.gif
		case diary
		// http://www.animatedgif.net/barslines/blink2_e0.gif
		case dividerBalls = "divider-balls"
		// http://www.animatedgif.net/animals/dogs/dogrun_e0.gif
		case dividerDog = "divider-dog"
		// http://www.animatedgif.net/animals/wateranimals/jumping_dolphin_e0.gif
		case dividerDolphin = "divider-dolphin"
		// http://www.animatedgif.net/barslines/ag_bar3_e0.gif
		case dividerDots = "divider-dots"
		// http://www.animatedgif.net/barslines/sliding_eyes_line_e0.gif
		case dividerEyes = "divider-eyes"
		// http://www.animatedgif.net/plants/flowerline2_e0.gif
		case dividerFlowers = "divider-flowers"
		// http://www.animatedgif.net/love/anheartline_e0.gif
		case dividerHearts = "divider-hearts"
		// http://www.animatedgif.net/barslines/hotbar_e0.gif
		case dividerHot = "divider-hot"
		// http://www.animatedgif.net/barslines/conelite_e0.gif
		case dividerLights = "divider-lights"
		// http://www.animatedgif.net/games/pacman-ln_e0.gif
		case dividerPacman = "divider-pacman"
		// http://www.animatedgif.net/barslines/barcol_e0.gif
		case dividerRainbow = "divider-rainbow"
		// http://www.animatedgif.net/stars/starline_e0.gif
		case dividerStars = "divider-stars"
		// http://www.animatedgif.net/musicsound/dj_e0.gif
		case dj
		// http://www.animatedgif.net/animals/wateranimals/dolphin2_e0.gif
		case dolphin
		// http://www.animatedgif.net/fireexplosions/dynamite_2_e0.gif
		case dynamite
		// http://www.animatedgif.net/email/at_e0.gif
		case emailSpin = "email-spin"
		// http://www.animatedgif.net/email/envelope_e0.gif
		case envelope
		// http://www.animatedgif.net/fireexplosions/explosion2_e0.gif
		case fire
		// http://www.animatedgif.net/fireexplosions/firew2_e0.gif
		case fireworks
		// http://www.animatedgif.net/animals/wateranimals/fishbowl_e0.gif
		case fishbowl
		// http://www.animatedgif.net/email/fishmail_e0.gif
		case fishMail = "fish-mail"
		// http://www.animatedgif.net/fireexplosions/flames_e0.gif
		case flames
		// http://www.animatedgif.net/fireexplosions/fireline_e0.gif
		case flamesBar = "flames-bar"
		// http://www.animatedgif.net/computers/floppy1_e0.gif
		case floppy
		// http://www.animatedgif.net/plants/flower_e0.gif
		case flower
		// http://www.animatedgif.net/animals/mystical/flying_pig_e0.gif
		case flyingPig = "flying-pig"
		// http://www.textfiles.com/underconstruction/ArArea51Station9771rulersconstructiongc_icon.gif
		case geoCitiesBanner = "geocities-banner"
		// http://www.animatedgif.net/earthglobe/earthrotate2_e0.gif
		case globe
		// http://www.animatedgif.net/earthglobe/earthrotate5_e0.gif
		case globeSmall = "globe-small"
		// http://www.animatedgif.net/stars/rotstar2_e0.gif
		case goldStar = "gold-star"
		// http://www.animatedgif.net/eyes/eyes3_e0.gif
		case googlyEyes = "googly-eyes"
		// http://www.animatedgif.net/animals/otheranimals/hamster_e0.gif
		case hamster
		// http://www.animatedgif.net/facessmiles/happy_e0.gif
		case happy
		// http://www.animatedgif.net/love/beat_hea_e0.gif
		case heart
		// http://www.animatedgif.net/welcome/dhhome256_e0.gif
		case home
		// http://www.animatedgif.net/fireexplosions/burninghot_e0.gif
		case hot
		// http://www.animatedgif.net/new/new_hot_e0.gif
		case hotBadge = "hot-badge"
		// http://www.animatedgif.net/sitemessages/misc/jchotjava_e0.gif
		case hotJava = "hot-java"
		// http://www.animatedgif.net/sitemessages/links/hotsites_e0.gif
		case hotSites = "hot-sites"
		// http://www.animatedgif.net/clockscounters/hrgla_e0.gif
		case hourglass
		// http://www.animatedgif.net/computers/imac67_e0.gif
		case iMac = "imac"
		// http://www.animatedgif.net/food/java_e0.gif
		case javaCup = "java-cup"
		// http://www.animatedgif.net/people/cgskipping_e0.gif
		case jumpRope = "jump-rope"
		// http://www.animatedgif.net/computers/comp6_e0.gif
		case kidComputer = "kid-computer"
		// https://www.animatedimages.org/data/media/510/animated-light-bulb-image-0003.gif
		case lightbulb
		// http://www.animatedgif.net/fireexplosions/lightning_e0.gif
		case lightning
		// http://www.animatedgif.net/email/anim0005-1_e0.gif
		case mailbox
		// http://www.animatedgif.net/email/bbclownm_e0.gif
		case mailMe = "mail-me"
		// http://www.animatedgif.net/email/mailrocket_e0.gif
		case mailRocket = "mail-rocket"
		// http://www.animatedgif.net/computers/gsm2_e0.gif
		case mobilePhone = "mobile-phone"
		// https://www.animatedimages.org/data/media/145/animated-internet-image-0006.gif
		case modem
		// http://www.animatedgif.net/animals/otheranimals/swinging_monkey_e0.gif
		case monkey
		// http://www.animatedgif.net/computers/mouse_e0.gif
		case mouse
		// http://www.animatedgif.net/musicsound/notefly_e0.gif
		case musicNotes = "music-notes"
		// http://www.animatedgif.net/sitemessages/home/lehome_e0.gif
		case navHome = "nav-home"
		// http://www.animatedgif.net/new/newupdat_e0.gif
		case newAndUpdated = "new-and-updated"
		// http://www.animatedgif.net/new/new6__e0.gif
		case newSmall = "new-small"
		// http://www.animatedgif.net/new/newspin1_e0.gif
		case newSpin = "new-spin"
		// http://www.animatedgif.net/new/new9_e0.gif
		case newStarburst = "new-starburst"
		// http://www.animatedgif.net/new/newstuf_e0.gif
		case newStuff = "new-stuff"
		// http://www.animatedgif.net/seasonal/newyears/yearend_e0.gif
		case newYear = "new-year"
		// http://www.animatedgif.net/new/jnnew8w_e0.gif
		case newYellow = "new-yellow"
		// http://www.animatedgif.net/flags/-flags-uncat/norway_gs_e0.gif
		case norwayFlag = "norway-flag"
		// http://www.animatedgif.net/games/pac20_e0.gif
		case pacman
		// http://www.animatedgif.net/animals/mystical/pegasus_e0.gif
		case pegasus
		// http://www.animatedgif.net/miscellaneous/phonespin_e0.gif
		case phone
		// http://www.animatedgif.net/miscellaneous/anibean_e0.gif
		case propellerHat = "propeller-hat"
		// http://www.animatedgif.net/animals/horses/lganunicorn_e0.gif
		case purpleUnicorn = "purple-unicorn"
		// http://www.animatedgif.net/sitemessages/faq/quesa_e0.gif
		case question
		// http://www.animatedgif.net/miscellaneous/rainbow1a_e0.gif
		case rainbow
		// http://www.animatedgif.net/sitemessages/guestbook/signbook_e0.gif
		case signGuestbook = "sign-guestbook"
		// http://www.animatedgif.net/people/awboxer_e0.gif
		case skeleton
		// http://www.animatedgif.net/devilish/rotateskull2_e0.gif
		case skull
		// http://www.animatedgif.net/sports/sheriski_e0.gif
		case skiSlope = "ski-slope"
		// http://www.animatedgif.net/sports/ice_dancer_e0.gif
		case iceDancer = "ice-dancer"
		// http://www.animatedgif.net/sports/slapshot_e0.gif
		case slapshot
		// http://www.animatedgif.net/sports/skier_e0.gif
		case skier
		// http://www.animatedgif.net/musicsound/cd2_e0.gif
		case compactDisc = "compact-disc"
		// http://www.animatedgif.net/miscellaneous/blinksmil_e0.gif
		case smiley
		// http://www.animatedgif.net/computers/dgee06_e0.gif
		case smileyComputer = "smiley-computer"
		// http://www.animatedgif.net/musicsound/speakers_e0.gif
		case sound
		// http://www.animatedgif.net/stars/star-3_e0.gif
		case sparkle
		// http://www.animatedgif.net/stars/pulsar-3_e0.gif
		case sparkles
		// http://www.animatedgif.net/computers/escdrom12_e0.gif
		case spinningCD = "spinning-cd"
		// http://www.animatedgif.net/miscellaneous/fanspin_e0.gif
		case spinningWheel = "spinning-wheel"
		// http://www.animatedgif.net/stars/starburst_e0.gif
		case starSpin = "star-spin"
		// http://www.animatedgif.net/people/dancanim_e0.gif
		case stickDance = "stick-dance"
		// http://www.animatedgif.net/fireexplosions/stormy_e0.gif
		case storm
		// http://www.animatedgif.net/food/toaster_e0.gif
		case toaster
		// https://www.animatedimages.org/data/media/517/animated-hamster-image-0001.gif
		case hamsterBanjo = "hamster-banjo"
		// https://www.animatedimages.org/data/media/517/animated-hamster-image-0002.gif
		case hamsterDrummer = "hamster-drummer"
		// https://www.animatedimages.org/data/media/517/animated-hamster-image-0004.gif
		case hamsterSinger = "hamster-singer"
		// https://www.animatedimages.org/data/media/517/animated-hamster-image-0021.gif
		case hamsterWhistler = "hamster-whistler"
		// https://www.animatedimages.org/data/media/517/animated-hamster-image-0022.gif
		case hamsterBassist = "hamster-bassist"
		// https://www.animatedimages.org/data/media/394/animated-record-player-image-0006.gif
		case turntableScratch = "turntable-scratch"
		// https://www.animatedimages.org/data/media/394/animated-record-player-image-0012.gif
		case alienDJ = "alien-dj"
		// https://www.animatedimages.org/data/media/384/animated-loudspeaker-image-0001.gif
		case speakerNotes = "speaker-notes"
		// https://www.animatedimages.org/data/media/387/animated-microphone-image-0004.gif
		case singingMicrophone = "singing-microphone"
		// https://www.animatedimages.org/data/media/378/animated-piano-image-0007.gif
		case crazyPianist = "crazy-pianist"
		// https://www.animatedimages.org/data/media/599/animated-radio-image-0029.gif
		case boombox
		// https://www.animatedimages.org/data/media/1377/animated-music-note-image-0002.gif
		case musicStaff = "music-staff"
		// http://www.animatedgif.net/sitemessages/misc/toparrow_e0.gif
		case topArrow = "top-arrow"
		// https://www.animatedimages.org/data/media/1467/animated-prize-and-award-image-0005.gif
		case trophy
		// http://www.animatedgif.net/space/jasaucer_e0.gif
		case ufo
		// http://www.textfiles.com/underconstruction/FaFashionAvenueShow5164underconstruction.gif
		case underConstructionBulldozer = "under-construction-bulldozer"
		// http://www.textfiles.com/underconstruction/Dungeon1253imagesconstruction016.gif
		case underConstructionCone = "under-construction-cone"
		// http://www.textfiles.com/underconstruction/babatdevimagesconstructioncrane.gif
		case underConstructionCrane = "under-construction-crane"
		// http://www.textfiles.com/underconstruction/AtAthensOlympus7403constructionman.gif
		case underConstructionDigger = "under-construction-digger"
		// http://www.textfiles.com/underconstruction/AtAthensOracle1388imagesconstruct.gif
		case underConstructionSign = "under-construction-sign"
		// http://www.textfiles.com/underconstruction/HoHollywoodAgency1055construction.gif
		case underConstructionStill = "under-construction-still"
		// http://www.textfiles.com/underconstruction/mmmmcloggersPicturesextrasconstruction.gif
		case underConstructionStripes = "under-construction-stripes"
		// http://www.textfiles.com/underconstruction/CoCollegePark8762construct.gif
		case underConstructionTape = "under-construction-tape"
		// https://www.animatedimages.org/data/media/477/animated-unicorn-image-0027.gif
		case unicorn
		// http://www.animatedgif.net/animals/mystical/unicorn4_e0.gif
		case unicornGallop = "unicorn-gallop"
		// http://www.animatedgif.net/sitemessages/misc/vote-here_e0.gif
		case voteHere = "vote-here"
		// http://www.animatedgif.net/animals/dogs/wagdog_e0.gif
		case waggingDog = "wagging-dog"
		// http://www.animatedgif.net/computers/diskman2_e0.gif
		case walkingComputer = "walking-computer"
		// http://www.animatedgif.net/welcome/welcometo_e0.gif
		case welcomeTo = "welcome-to"
		// http://www.animatedgif.net/new/new6-1_e0.gif
		case whatsNew = "whats-new"
		// http://www.animatedgif.net/devilish/wizard1_e0.gif
		case wizard
		// https://www.animatedimages.org/data/media/962/animated-at-sign-image-0004.gif
		case atGold = "at-gold"
		// http://www.animatedgif.net/barslines/ballfly_e0.gif
		case bulletBall = "bullet-ball"
		// https://cyber.dabamos.de/88x31/bestviewed16bit.gif
		case button16Bit = "button-16-bit"
		// https://cyber.dabamos.de/88x31/get3dnow.gif
		case button3DNow = "button-3dnow"
		// https://cyber.dabamos.de/88x31/auzzie1.gif
		case buttonAuzzie = "button-auzzie"
		// https://cyber.dabamos.de/88x31/besteyes2.gif
		case buttonBestViewedEyes = "button-best-viewed-eyes"
		// https://cyber.dabamos.de/88x31/cool-shades.gif
		case buttonCoolShades = "button-cool-shades"
		// https://cyber.dabamos.de/88x31/cooltxt.gif
		case buttonCoolText = "button-cool-text"
		// https://cyber.dabamos.de/88x31/dhtml.gif
		case buttonDHTML = "button-dhtml"
		// https://cyber.dabamos.de/88x31/flamingtext.gif
		case buttonFlamingText = "button-flaming-text"
		// https://cyber.dabamos.de/88x31/javascript.gif
		case buttonJavaScript = "button-javascript"
		// https://cyber.dabamos.de/88x31/lynx.gif
		case buttonLynx = "button-lynx"
		// https://cyber.dabamos.de/88x31/netscapenow40.gif
		case buttonNetscapeNow4 = "button-netscape-now-4"
		// https://cyber.dabamos.de/88x31/256_monitor_button.gif
		case buttonOldMonitor = "button-old-monitor"
		// http://www.textfiles.com/underconstruction/thefirepoliceconstruction10.gif
		case cautionSlowWebmaster = "caution-slow-webmaster"
		// https://www.animatedimages.org/data/media/56/animated-computer-image-0005.gif
		case computerSmash = "computer-smash"
		// http://www.textfiles.com/underconstruction/HeHeartlandRanch4242Imagesconstruction_blinkers.gif
		case constructionBlinkers = "construction-blinkers"
		// http://www.textfiles.com/underconstruction/Orion8291Lightningunderconstruction04.gif
		case constructionLightning = "construction-lightning"
		// https://www.animatedimages.org/data/media/56/animated-computer-image-0057.gif
		case copyingFiles = "copying-files"
		// https://www.animatedimages.org/data/media/1128/animated-dancing-baby-image-0001.gif
		case dancingBaby = "dancing-baby"
		// https://www.animatedimages.org/data/media/107/animated-dancing-image-0023.gif
		case dancingBallet = "dancing-ballet"
		// https://www.animatedimages.org/data/media/330/animated-banana-image-0015.gif
		case dancingBanana = "dancing-banana"
		// https://www.animatedimages.org/data/media/198/animated-frog-image-0027.gif
		case dancingFrog = "dancing-frog"
		// https://www.animatedimages.org/data/media/107/animated-dancing-image-0018.gif
		case dancingMoonwalk = "dancing-moonwalk"
		// https://www.animatedimages.org/data/media/1139/animated-disco-light-image-0001.gif
		case discoLights = "disco-lights"
		// http://www.animatedgif.net/barslines/ants_e0.gif
		case dividerAnts = "divider-ants"
		// http://www.animatedgif.net/barslines/arrtan_e0.gif
		case dividerArrows = "divider-arrows"
		// http://www.animatedgif.net/barslines/2birds2_e0.gif
		case dividerBirds = "divider-birds"
		// http://www.animatedgif.net/barslines/anicomg_e0.gif
		case dividerComet = "divider-comet"
		// http://www.animatedgif.net/barslines/ag_bar3_e0.gif
		case dividerDiscoDots = "divider-disco-dots"
		// http://www.animatedgif.net/barslines/abar5_e0.gif
		case dividerEmail = "divider-email"
		// http://www.animatedgif.net/barslines/ag_boom_line_e0.gif
		case dividerFuse = "divider-fuse"
		// http://www.animatedgif.net/barslines/bartwo_e0.gif
		case dividerHazard = "divider-hazard"
		// https://www.animatedimages.org/data/media/134/animated-dividing-line-image-0053.gif
		case dividerHelix = "divider-helix"
		// http://www.animatedgif.net/barslines/bar_eleg_e0.gif
		case dividerLaser = "divider-laser"
		// http://www.animatedgif.net/barslines/ani_rline_e0.gif
		case dividerRainbowDashes = "divider-rainbow-dashes"
		// http://www.animatedgif.net/barslines/barspark_e0.gif
		case dividerSparkle = "divider-sparkle"
		// http://www.animatedgif.net/barslines/barstar_e0.gif
		case dividerStarburst = "divider-starburst"
		// https://www.animatedimages.org/data/media/235/animated-email-image-0002.gif
		case emailAtRed = "email-at-red"
		// https://www.animatedimages.org/data/media/235/animated-email-image-0016.gif
		case envelopeFlying = "envelope-flying"
		// https://www.animatedimages.org/data/media/90/animated-fire-image-0419.gif
		case flamesWide = "flames-wide"
		// https://www.animatedimages.org/data/media/1256/animated-home-sign-image-0007.gif
		case homeHouse = "home-house"
		// https://www.animatedimages.org/data/media/1256/animated-home-sign-image-0028.gif
		case homeNeon = "home-neon"
		// https://www.animatedimages.org/data/media/531/animated-hot-image-0007.gif
		case hotBurst = "hot-burst"
		// https://www.animatedimages.org/data/media/531/animated-hot-image-0011.gif
		case hotFlames = "hot-flames"
		// https://www.animatedimages.org/data/media/235/animated-email-image-0023.gif
		case mailMeRainbow = "mail-me-rainbow"
		// https://www.animatedimages.org/data/media/1381/animated-neon-text-image-0007.gif
		case neonOpen = "neon-open"
		// https://www.animatedimages.org/data/media/583/animated-new-image-0009.gif
		case newFlames = "new-flames"
		// https://www.animatedimages.org/data/media/583/animated-new-image-0001.gif
		case newRainbow = "new-rainbow"
		// https://www.animatedimages.org/data/media/235/animated-email-image-0038.gif
		case sendEmail = "send-email"
		// https://www.animatedimages.org/data/media/1197/animated-flashing-and-emergency-light-image-0005.gif
		case siren = "siren"
		// https://www.animatedimages.org/data/media/687/animated-skull-image-0017.gif
		case skullFlaming = "skull-flaming"
		// https://www.animatedimages.org/data/media/687/animated-skull-image-0005.gif
		case skullSmoking = "skull-smoking"

		var path: RoutePath {
			RoutePath("/1999/\(rawValue).gif")
		}

		/**
		The still frame, for visitors who prefer reduced motion. Only GIFs that move have one.
		*/
		var stillPath: RoutePath {
			RoutePath("/1999/still/\(rawValue).gif")
		}
	}
}
