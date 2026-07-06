class_name ArcweaveStrings

const START_TROLLEY: String = "4f41e84a-9ec3-4bb5-a434-80cc705587f3"
const SCENARIO_COMPLETE: String = "b20b2bd8-4972-4c3f-83df-83b2479fe83a"

const INACTION_x1: StringName = &"Inaction_x1"
const INTERVENTION_x1: StringName = &"Intervention_x1"

const KEY_MOMENT: String = "cba86ed8-c7c8-4326-b095-11099033e6eb"
const WEIGHT_1: String = "8ddddbe9-ab5a-4b35-9efb-5420ea9cc8af"
const WEIGHT_2: String = "a81c28a9-bb9d-4fdc-ae83-6f607eaba941"

const HARM: String = "d48d83a2-5fe8-4454-9e5a-e45282863f37"
const PRIDE: String = "890c658e-e0d2-4efb-bee8-ac9a54547133"
const NEGLECT: String = "d18d1371-6c9b-43b5-b40e-5703034f9110"
const DEGREDATION: String = "c679cb5f-226e-4348-845d-3dde65282f86"
const OPPRESSION: String = "25cc5d0c-e15b-4519-b6ab-b7c898b0ee31"
const SUBVERSION: String = "15afca38-a152-453c-b062-33762a31c826"
const BETRAYAL: String = "6ad1dd2c-d383-4cb5-a2c1-b2efb06e7b44"
const CHEATING: String = "c3f68887-106e-4ea1-9f57-4d44829b5bf3"

const HUMILITY: String = "d8918d9a-c753-4177-b478-80ed5eb8febe"
const DUTY: String = "c4f8b7cb-da4c-43fc-9069-f4afe4073d45"
const SANCTITY: String = "c7f670f1-9f44-4ff4-be03-48f656c59ece"
const LIBERTY: String = "68767e00-f7de-44de-ad26-dccc189b0001"
const AUTHORITY: String = "7414ad50-434b-4454-97a7-533770a72c5a"
const LOYALTY: String = "9ad36259-6f0d-4db3-b117-feca239e6642"
const FAIRNESS: String = "a8b8e7f0-7268-4980-b4b7-b9ab69b44a1b"
const CARE: String = "32c2ca99-e388-4bb8-91ff-f6e9f7d473de"

const NARRATIVE_TAGS: Dictionary[String, String] = {
	HARM: "Harm",
	PRIDE: "Pride",
	NEGLECT: "Neglect",
	DEGREDATION: "Degredation",
	OPPRESSION: "Oppression",
	SUBVERSION: "Subversion",
	BETRAYAL: "Betrayal",
	CHEATING: "Cheating",

	HUMILITY: "Humility",
	DUTY: "Duty",
	SANCTITY: "Sanctity",
	LIBERTY: "Liberty",
	AUTHORITY: "Authority",
	LOYALTY: "Loyalty",
	FAIRNESS: "Fairness",
	CARE: "Care",
}

## Returns tag name if found, else an empty String.
static func is_narrative_tag(tag_id: String) -> String:
	return NARRATIVE_TAGS.get(tag_id, "")
