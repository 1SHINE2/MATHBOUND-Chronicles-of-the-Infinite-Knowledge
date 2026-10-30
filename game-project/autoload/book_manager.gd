extends Node
## Manages the 3-Layer Digital Book (1. Chronicle, 2. Knowledge, 3. Archive),
## Document 3-Question Inquiry, End-of-Volume Advanced Side Quests, and Sync Codes.

signal archive_entry_unlocked(entry_id: String, title: String)
signal chapter_unlocked(chapter_id: String)
signal side_quest_solved(quest_id: String)

var chapters: Array[Dictionary] = [
	{
		"id": "chronicle_ch1",
		"book_number": 1,
		"book_title": "Book I — Elementary Mathematics (The Magical Academy)",
		"chapter_number": 1,
		"title": "The Library of Shadows",
		"subtitle": "Ordinary World & The Ancient Engraving",
		"unlocked": true,
		"sync_code": "BOOK1-CH1",
		"narrative_text": [
			"In an ordinary school on an ordinary weekday afternoon, Samantha Yu (10) and Miguel Perez (11) found themselves drawn to the quietest corridor of the campus library.",
			"Neither was chosen by destiny; neither sought to fulfill a grand prophecy. They were simply two curious childhood friends who noticed an odd series of anomalies—books aligned to geometric proportions and dust motes settling in perfect spirals.",
			"Tucked behind the reference stacks lay the first volume: Chronicles of the Infinite Knowledge. On its heavy parchment cover rested an ancient engraving associated with Book I.",
			"When they activated the engraving together, a blinding flash of crystalline light transported them into MATHBOUND."
		],
		"key_event": "Activation of the Book I Engraving in the School Library",
		"annotations": ["documents_five_rules", "places_book_one"],
		"samantha_reflection": "\"It wasn't magic pulling us in—it felt like we were opening an invitation to understand what had always been right in front of us.\"",
		"miguel_reflection": "\"The engraving wasn't random decoration. The grooves formed a complete closed geometric circuit. Touching it completed the structure.\""
	},
	{
		"id": "chronicle_ch2",
		"book_number": 1,
		"book_title": "Book I — Elementary Mathematics (The Magical Academy)",
		"chapter_number": 2,
		"title": "The Voice and the Five Rules",
		"subtitle": "Arrival in the Magical Academy & The Floating Stones",
		"unlocked": true,
		"sync_code": "BOOK1-CH2",
		"narrative_text": [
			"When the light settled, Samantha and Miguel stood upon ancient cobblestones framed by floating islands, cascading waterfalls, and monolithic stone arches.",
			"A mysterious voice introduced them to the Five Rules of MATHBOUND:\n• Rule I (Perception): \"What you see, you can understand. What you cannot see, you must question.\"\n• Rule II (Doubt): \"What you believe may be true. It may also be wrong.\"\n• Rule III (Inquiry): \"Question what you know. Question what you don't know.\"\n• Rule IV (Discovery): \"The unknown is not something to fear. It is something to uncover.\"\n• Rule V (Invitation): \"Open your minds, have fun... and let's find out.\"",
			"Near the courtyard chasm, a glowing blue Magic Sprite named Auri hovered beside six floating stones. Through the Two-Table system—Envisioning a bridge and Commanding Count(6) with the Counting Sigil—the stones aligned into a path."
		],
		"key_event": "Imparting of the Five Rules & First Magic Sprite Interaction",
		"annotations": ["words_two_table_magic", "objects_focus"],
		"samantha_reflection": "\"Rule II hit me immediately. Believing something doesn't make it reality. Truth exists whether we agree or not.\"",
		"miguel_reflection": "\"Mathematics isn't fuel stored inside us. It's the formal language we use on the Command table so the Magic Sprite understands our intention!\""
	},
	{
		"id": "chronicle_ch3",
		"book_number": 1,
		"book_title": "Book I — Elementary Mathematics (The Magical Academy)",
		"chapter_number": 3,
		"title": "The Forbidden Gate of Foundations",
		"subtitle": "Requirement Locks & The Doubling Ratio",
		"unlocked": false,
		"sync_code": "GATE-64",
		"narrative_text": [
			"Caretaker Oron explained that the Great Patterned Gate locks scholars out of the northern Sequence Sanctum until they demonstrate mastery of geometric progression.",
			"Examining the four active sockets—4, 8, 16, 32—Samantha and Miguel tested their hypotheses at the Courtyard Working Slate.",
			"By supplying 64 to satisfy the constant common ratio (r = 2), the requirement lock released with a deep resonant hum."
		],
		"key_event": "Unsealing the Requirement-Locked Gate via Geometric Progression (64)",
		"annotations": ["objects_gate", "words_geometric", "documents_inscription"],
		"samantha_reflection": "\"The gate wasn't locked out of malice; it was protecting an area we weren't ready to interpret until we understood exponential growth.\"",
		"miguel_reflection": "\"Each socket doubled the preceding value: 32 × 2 = 64. Once the requirement was satisfied, the barrier yielded.\""
	},
	{
		"id": "chronicle_ch4",
		"book_number": 1,
		"book_title": "Book I — Elementary Mathematics (The Magical Academy)",
		"chapter_number": 4,
		"title": "Trial of the Sequence Warden",
		"subtitle": "Chapter Elite Culmination & The Unfinished Mystery",
		"unlocked": false,
		"sync_code": "WARDEN-ELITE",
		"narrative_text": [
			"Inside the Sequence Sanctum, the Chapter Elite—the Sequence Warden—awakened to test their understanding in motion.",
			"By reading the telegraphed floor sequences and channeling spells from their Magical Codex, Samantha and Miguel overcame the trial and earned the Warden's Resonance Sigil.",
			"Yet deeper questions remained: Who or what is the Creator of the Chronicles? And what lies beyond the Academy in the Solarpunk Metropolis of Book II?"
		],
		"key_event": "Victory over the Sequence Warden (Chapter Elite) & Opening the Grand Archive",
		"annotations": ["people_warden", "documents_creator_mystery", "places_four_books"],
		"samantha_reflection": "\"Every answer we find opens three new questions. Maybe the Creator isn't a person hiding behind a curtain at all...\"",
		"miguel_reflection": "\"Chapter -> Elite, Volume -> Sub-boss, Book -> Boss. We've passed our first Elite milestone, and our Magical Codex is growing.\""
	}
]

var archive_entries: Array[Dictionary] = [
	{
		"id": "people_samantha",
		"title": "Samantha Yu (Age 10)",
		"category": "People",
		"summary": "Co-protagonist associated with Meditative Thinking (\"What does it mean?\").",
		"detailed_text": "Samantha Yu (initial age 10, height 4'11\") entered MATHBOUND alongside her childhood friend Miguel Perez. She reflects on meaning, interpretation, implications, and underlying assumptions.",
		"discovered": true,
		"related_ids": ["people_miguel", "documents_five_rules"]
	},
	{
		"id": "people_miguel",
		"title": "Miguel Perez (Age 11)",
		"category": "People",
		"summary": "Co-protagonist associated with Calculative Thinking (\"How does it work?\").",
		"detailed_text": "Miguel Perez (initial age 11, height 5'4\") entered MATHBOUND alongside Samantha Yu. He investigates mechanisms, quantitative relationships, procedures, and how individual parts contribute to a result.",
		"discovered": true,
		"related_ids": ["people_samantha", "documents_five_rules"]
	},
	{
		"id": "people_auri",
		"title": "Auri & Magic Sprites",
		"category": "People",
		"summary": "Living, personality-bearing manifestations of magic associated with environments.",
		"detailed_text": "In Story Bible v0.09 & Magic System v0.10.01, Magic Sprites are living creatures with their own personalities and capabilities. They are not passive mana batteries. Practitioners use mathematical expressions and sigils to communicate intentions to Sprites, which interpret and enact them within reality's limits.",
		"discovered": true,
		"related_ids": ["words_two_table_magic", "objects_focus"]
	},
	{
		"id": "people_oron",
		"title": "Caretaker Oron",
		"category": "People",
		"summary": "Senior groundskeeper overseeing the Academy Outpost and its requirement gates.",
		"detailed_text": "Caretaker Oron maintains the outer courtyard of the Magical Academy and guides newcomers toward the Proving Table and Scholastic Chalkboard.",
		"discovered": false,
		"related_ids": ["places_outpost", "objects_gate"]
	},
	{
		"id": "people_warden",
		"title": "The Sequence Warden (Chapter Elite)",
		"category": "People",
		"summary": "Ancient automaton guardian serving as the Chapter Elite culmination.",
		"detailed_text": "Following the canonical hierarchy (Book -> Boss, Volume -> Sub-boss, Chapter -> Elite), the Sequence Warden tests whether scholars can apply pattern recognition under pressure.",
		"discovered": false,
		"related_ids": ["places_sanctum", "words_progression_hierarchy"]
	},
	{
		"id": "people_the_order",
		"title": "The Order & Intelligent Races",
		"category": "People",
		"summary": "Public administration institution across a world of Humans, Elves, Dwarves, and Demi-humans.",
		"detailed_text": "The Order oversees public safety, magical regulation, research, and education. MATHBOUND is inhabited by Humans, Elves, Dwarves, and Demi-humans—each with distinct cultural traditions of Formalized and Experiential magic.",
		"discovered": true,
		"related_ids": ["places_four_books"]
	},
	{
		"id": "places_outpost",
		"title": "The Magical Academy (Book I)",
		"category": "Places",
		"summary": "Whimsical sky-island academy with warm stonework and icy magical touches (Grades 1–6).",
		"detailed_text": "Book I centers on the Magical Academy, where elementary mathematics (counting, operations, patterns, measurement, geometry) is encountered through living phenomena, courtyards, libraries, and Proving Tables.",
		"discovered": true,
		"related_ids": ["places_four_books", "people_oron"]
	},
	{
		"id": "places_four_books",
		"title": "The Four-Book Mainline & Side Stories",
		"category": "Places",
		"summary": "The overarching 10–20 year journey across Books I–IV and specialized Books V–X.",
		"detailed_text": "• Book I (Grades 1–6): The Magical Academy\n• Book II (Grades 7–10): The Solarpunk Metropolis\n• Book III (Grades 11–12): Senior High School Transition (Identity Open)\n• Book IV (The Finale): Narrative & Philosophical Culmination\n• Books V–X+: Specialized college/applied mathematics side stories.",
		"discovered": true,
		"related_ids": ["places_outpost", "documents_creator_mystery"]
	},
	{
		"id": "places_sanctum",
		"title": "The Sequence Sanctum (Forbidden Zone)",
		"category": "Places",
		"summary": "Restricted northern chamber locked behind the Patterned Gate requirement.",
		"detailed_text": "Areas beyond requirement gates are sealed to scholars until they acquire the necessary mathematical understanding and sigil mastery.",
		"discovered": false,
		"related_ids": ["objects_gate", "people_warden"]
	},
	{
		"id": "documents_five_rules",
		"title": "The Five Rules of MATHBOUND",
		"category": "Documents",
		"summary": "Foundational philosophical principles spoken upon entering Book I.",
		"detailed_text": "Rule I — Perception: \"What you see, you can understand. What you cannot see, you must question.\"\nRule II — Doubt: \"What you believe may be true. It may also be wrong.\"\nRule III — Inquiry: \"Question what you know. Question what you don't know.\"\nRule IV — Discovery: \"The unknown is not something to fear. It is something to uncover.\"\nRule V — Invitation: \"Open your minds, have fun... and let's find out.\"",
		"discovered": true,
		"inquiry": {
			"is_it_real": "Heard directly by both Samantha and Miguel upon their arrival in Book I.",
			"what_does_it_mean": "Establishes that knowledge is fallible, curiosity has consequences, and there is always more to discover.",
			"what_can_it_tell_us": "Every puzzle, spell, and mystery in MATHBOUND rewards observation and testing hypotheses."
		},
		"related_ids": ["people_samantha", "people_miguel"]
	},
	{
		"id": "documents_inscription",
		"title": "The Inscription of Rhythms",
		"category": "Documents",
		"summary": "Chiseled theorem above the Requirement Gate describing exponential doubling.",
		"detailed_text": "\"When the threshold locks against the unprepared, look to the ratio of increase. What was four becomes eight; what was sixteen doubles to thirty-two. Supply the fifth harmonic term, and the forbidden path shall open.\"",
		"discovered": false,
		"math_concept": {
			"topic": "Geometric Sequences & Common Ratio",
			"rule": "Each term equals the preceding term multiplied by a constant ratio r = 2.",
			"formula": "a_n = a_1 · 2^(n-1)  →  4, 8, 16, 32, 64",
			"explanation": "Unlike arithmetic sequences that add a constant difference (+4), geometric sequences scale by multiplication (×2).",
			"example": "Socket 1 = 4, Socket 2 = 8, Socket 3 = 16, Socket 4 = 32, Socket 5 = 32 × 2 = 64."
		},
		"inquiry": {
			"is_it_real": "Authentic Academy stonework linked directly to the gate's runic circuit.",
			"what_does_it_mean": "The gate requires the 5th term of the doubling sequence (64).",
			"what_can_it_tell_us": "We can unlock the gate either through the Rune Socket puzzle or by constructing Multiply(32, 2) / Count(64)."
		},
		"related_ids": ["objects_gate", "words_geometric"]
	},
	{
		"id": "documents_creator_mystery",
		"title": "The Creator & The Unfinished Book",
		"category": "Documents",
		"summary": "Central mystery regarding the Chronicles and the abstract nature of Mathematics.",
		"detailed_text": "The Chronicles recordWritten, Rewritten, and Unwritten knowledge. The Creator is not a conventional physical deity or secret mastermind, but an abstract representation of Mathematics itself—the reality that has always existed, waiting to be understood.",
		"discovered": false,
		"inquiry": {
			"is_it_real": "Debated across civilizations; fragments appear in the oldest Archive layers.",
			"what_does_it_mean": "The world is not limited to what is written in the Chronicles; the Chronicles are limited by what humanity has understood so far.",
			"what_can_it_tell_us": "Even at the end of Book IV, an unfinished Book and quill await: there is always more to discover."
		},
		"related_ids": ["places_four_books"]
	},
	{
		"id": "objects_focus",
		"title": "Resonant Focus & The Proving Table",
		"category": "Objects",
		"summary": "Magical interfaces that facilitate communication with Magic Sprites.",
		"detailed_text": "Magical devices (staffs, wands, rings, Proving Tables) are interfaces, not mana batteries. They help practitioners structure sigils and mathematical units to communicate clearly with Magic Sprites.",
		"discovered": true,
		"related_ids": ["words_two_table_magic", "people_auri"]
	},
	{
		"id": "objects_gate",
		"title": "Requirement-Locked Gates",
		"category": "Objects",
		"summary": "Magical barriers sealing forbidden zones until a scholar meets the required competency.",
		"detailed_text": "Placed at key thresholds across the Academy, Requirement Gates prevent entry into hazardous or advanced areas until the practitioner possesses the required sigils, mathematical competency, or authorization.",
		"discovered": true,
		"related_ids": ["documents_inscription", "places_sanctum"]
	},
	{
		"id": "words_two_table_magic",
		"title": "The Two-Table System & Sigil Grammar",
		"category": "Words",
		"summary": "Envision (What I want to happen) + Command (How I express it mathematically).",
		"detailed_text": "Spellcasting follows four layers:\n1. Mathematical Language (Sigils with strict mathematical equivalence + input values)\n2. Magical Communication (Table I: Envision -> Table II: Command)\n3. Magical Interpretation (Magic Sprite evaluates the expression)\n4. World Response (Success, or diagnostic feedback distinguishing Math error, Sprite capability limit, Communication failure, or Environmental limitation).",
		"discovered": true,
		"math_concept": {
			"topic": "Cardinality, Operations & Formal Expression Structure",
			"rule": "One mathematical meaning per sigil, potentially many magical applications.",
			"formula": "Envision(Outcome) + Command(Sigil, Inputs) -> Sprite Interpretation -> Response",
			"explanation": "Counting (Count(6)) identifies the cardinality of a collection; Operations (Add(3,3), Multiply(32,2)) combine or scale quantities.",
			"example": "To align 6 floating stones: Envision = Bridge, Command = Count(6) or Add(3, 3)."
		},
		"related_ids": ["people_auri", "objects_focus"]
	},
	{
		"id": "words_geometric",
		"title": "Arithmetic vs. Geometric Progression",
		"category": "Words",
		"summary": "Distinguishing constant addition differences (+d) from constant multiplication ratios (×r).",
		"detailed_text": "When investigating a numerical pattern in the environment, first test the difference between consecutive terms (a_n - a_{n-1}). If the difference changes, test the ratio (a_n / a_{n-1}).",
		"discovered": false,
		"math_concept": {
			"topic": "Linear (Arithmetic) vs. Exponential (Geometric) Growth",
			"rule": "Arithmetic: a_n = a_1 + (n-1)d   |   Geometric: a_n = a_1 · r^(n-1)",
			"formula": "d = a_n - a_{n-1}   vs.   r = a_n / a_{n-1}",
			"explanation": "Comparing linear addition against exponential multiplication prevents false assumptions (Rule II).",
			"example": "Arithmetic (+4): 4, 8, 12, 16, 20. Geometric (×2): 4, 8, 16, 32, 64."
		},
		"related_ids": ["documents_inscription", "objects_gate"]
	},
	{
		"id": "words_progression_hierarchy",
		"title": "Narrative & Encounter Hierarchy",
		"category": "Words",
		"summary": "Book -> Boss | Volume -> Sub-boss | Chapter -> Elite.",
		"detailed_text": "Every culmination in MATHBOUND reflects what the protagonists have learned:\n• Chapter -> Elite (focused test of the chapter's concept)\n• Volume -> Sub-boss (intermediate synthesis across a volume)\n• Book -> Boss (grand culmination of the entire Book).",
		"discovered": true,
		"related_ids": ["people_warden", "places_four_books"]
	}
]

# Optional End-of-Volume Archive Side Quests (Story Bible v0.09 Section 32)
var archive_side_quests: Array[Dictionary] = [
	{
		"id": "sidequest_al_khwarizmi",
		"title": "Archive Side Quest I: The Ancient Balance of Al-Khwarizmi",
		"historical_note": "Real Mathematical History: In the 9th century, the scholar Muhammad ibn Musa al-Khwarizmi wrote 'Al-Jabr', introducing systematic balancing of equations.",
		"prompt": "A fractured Archive tablet requires balancing two magical scales so both sides equal 24. Which Command expression balances 3 groups of 8?",
		"options": ["Multiply(3, 8)", "Add(3, 8)", "Subtract(24, 8)"],
		"correct_option": "Multiply(3, 8)",
		"solved": false,
		"reward_spell_id": "spell_mirror_step",
		"reward_text": "Unlocked 'Mirror Step (Lv. 4)' in the Magical Codex!"
	},
	{
		"id": "sidequest_fibonacci",
		"title": "Archive Side Quest II: Leonardo of Pisa's Botanical Spiral",
		"historical_note": "Real Mathematical History: The Fibonacci sequence (1, 1, 2, 3, 5, 8, 13, 21...) appears in pine cones, sunflower seeds, and historical texts from India and Italy.",
		"prompt": "Each term in the Academy's botanical spiral is the sum of the two preceding terms: 2, 3, 5, 8, 13, [?]. Which expression constructs the next term?",
		"options": ["Add(8, 13)", "Multiply(8, 2)", "Count(19)"],
		"correct_option": "Add(8, 13)",
		"solved": false,
		"reward_spell_id": "spell_time_knot",
		"reward_text": "Unlocked 'Time Knot (Lv. 4)' in the Magical Codex!"
	}
]

func unlock_archive_entry(entry_id: String) -> void:
	for entry in archive_entries:
		if entry["id"] == entry_id and not entry["discovered"]:
			entry["discovered"] = true
			AudioManager.play_archive_unlock()
			archive_entry_unlocked.emit(entry_id, entry["title"])
			return

func unlock_chapter(chapter_id: String) -> void:
	for ch in chapters:
		if ch["id"] == chapter_id and not ch["unlocked"]:
			ch["unlocked"] = true
			chapter_unlocked.emit(chapter_id)
			return

func get_knowledge_entries() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry in archive_entries:
		if entry.has("math_concept") and entry["discovered"]:
			list.append(entry)
	return list

func get_discovered_archive_count() -> int:
	var c := 0
	for entry in archive_entries:
		if entry["discovered"]:
			c += 1
	return c

## Sync Code system connecting standalone Digital Book readers to the Digital Game
func apply_sync_code(raw_code: String) -> Dictionary:
	var code := raw_code.strip_edges().to_upper()
	match code:
		"BOOK1-CH1", "CH1":
			unlock_chapter("chronicle_ch1")
			return {"success": true, "message": "Synced Chapter 1: The Library of Shadows!"}
		"BOOK1-CH2", "PROVE-COUNT":
			unlock_chapter("chronicle_ch2")
			MagicManager.encounters["encounter_floating_stones"]["solved"] = true
			CodexManager.unlock_spell("spell_harmonic_bridge")
			return {"success": true, "message": "Synced Chapter 2 & Unlocked 'Water Bridge' Spell!"}
		"BOOK1-CH3", "GATE-64":
			unlock_chapter("chronicle_ch3")
			MagicManager.encounters["encounter_patterned_gate"]["solved"] = true
			unlock_archive_entry("documents_inscription")
			unlock_archive_entry("words_geometric")
			return {"success": true, "message": "Synced Chapter 3: Patterned Gate Unsealed (64)!"}
		"BOOK1-CH4", "WARDEN-ELITE", "CODEX-ALL":
			for ch in chapters:
				ch["unlocked"] = true
			for entry in archive_entries:
				entry["discovered"] = true
			for spell_id in CodexManager.spells:
				CodexManager.spells[spell_id]["unlocked"] = true
			AudioManager.play_archive_unlock()
			return {"success": true, "message": "Master Chronicle Sync Complete: All Chapters, Archive Records & 12 Codex Spells Unlocked!"}
		_:
			AudioManager.play_error()
			return {"success": false, "message": "Unrecognized Sync Code. Try: BOOK1-CH2, GATE-64, or CODEX-ALL."}
