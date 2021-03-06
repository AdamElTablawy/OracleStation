/datum/surgery/organ_manipulation
	name = "organ manipulation"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/retract_skin, /datum/surgery_step/saw, /datum/surgery_step/clamp_bleeders,
	/datum/surgery_step/incise, /datum/surgery_step/manipulate_organs)
	species = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list("chest", "head")
	bodypart_types = BODYPART_ORGANIC
	requires_real_bodypart = TRUE

/datum/surgery/organ_manipulation/soft
	possible_locs = list("groin", "eyes", "mouth", "l_arm", "r_arm")
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/retract_skin, /datum/surgery_step/clamp_bleeders,
	/datum/surgery_step/incise, /datum/surgery_step/manipulate_organs)

/datum/surgery/organ_manipulation/alien
	name = "alien organ manipulation"
	possible_locs = list("chest", "head", "groin", "eyes", "mouth", "l_arm", "r_arm")
	species = list(/mob/living/carbon/alien/humanoid)
	steps = list(/datum/surgery_step/saw, /datum/surgery_step/incise, /datum/surgery_step/retract_skin, /datum/surgery_step/saw, /datum/surgery_step/manipulate_organs)




/datum/surgery_step/manipulate_organs
	time = 64
	name = "manipulate organs"
	implements = list(/obj/item/organ = 100, /obj/item/reagent_containers/food/snacks/organ = 0, /obj/item/organ_storage = 100, /obj/item/device/mmi = 100)
	var/implements_extract = list(/obj/item/hemostat = 100, /obj/item/crowbar = 55)
	var/implements_mend = list(/obj/item/cautery = 100, /obj/item/weldingtool = 70, /obj/item/lighter = 45, /obj/item/match = 20)
	var/current_type
	var/mend_the_incision = "mend the incision in"//so we can reuse the whole thing for robotic surgery
	var/mends_the_incision = "mends the incision in"
	var/obj/item/organ/I = null

/datum/surgery_step/manipulate_organs/New()
	..()
	implements = implements + implements_extract + implements_mend

/datum/surgery_step/manipulate_organs/tool_check(mob/user, obj/item/tool)
	if(istype(tool, /obj/item/weldingtool))
		var/obj/item/weldingtool/WT = tool
		if(!WT.isOn())
			return 0

	else if(istype(tool, /obj/item/lighter))
		var/obj/item/lighter/L = tool
		if(!L.lit)
			return 0

	else if(istype(tool, /obj/item/match))
		var/obj/item/match/M = tool
		if(!M.lit)
			return 0

	return 1


/datum/surgery_step/manipulate_organs/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	I = null
	if(istype(tool, /obj/item/organ_storage))
		if(!tool.contents.len)
			to_chat(user, "<span class='notice'>There is nothing inside [tool]!</span>")
			return -1
		I = tool.contents[1]
		if(!isorgan(I))
			to_chat(user, "<span class='notice'>You cannot put [I] into [target]'s [parse_zone(target_zone)]!</span>")
			return -1
		tool = I
	if(istype(tool, /obj/item/device/mmi))//this whole thing is only used for robotic surgery in organ_mani_robotic.dm :*
		current_type = "posibrain"
		var/obj/item/bodypart/affected = target.get_bodypart(check_zone(target_zone))
		if(!affected)
			return -1
		if(affected.status != ORGAN_ROBOTIC)
			to_chat(user, "<span class='notice'>You can't put [tool] into a meat enclosure!</span>")
			return -1
		if(!isipc(target))
			to_chat(user, "<span class='notice'>[target] does not have the proper connectors to interface with [tool].</span>")
			return -1
		if(target_zone != "chest")
			to_chat(user, "<span class='notice'>You have to install [tool] in [target]'s chest!</span>")
			return -1
		if(target.internal_organs_slot[ORGAN_SLOT_BRAIN])
			to_chat(user, "<span class='notice'>[target] already has a brain! You'd rather not find out what would happen with two in there.</span>")
			return -1
		var/obj/item/device/mmi/P = tool
		if(!istype(P))
			return -1
		if(!P.brainmob || !P.brainmob.client)
			to_chat(user, "<span class='notice'>[tool] has no life in it, this would be pointless!</span>")
			return -1
		user.visible_message("<span class='notice'>[user] begins to insert [tool] into [target]'s [parse_zone(target_zone)].</span>",
			"<span class='notice'>You begin to insert [tool] into [target]'s [parse_zone(target_zone)]...</span>")

	if(isorgan(tool))
		current_type = "insert"
		I = tool
		if(target_zone != I.zone || target.getorganslot(I.slot))
			to_chat(user, "<span class='notice'>There is no room for [I] in [target]'s [parse_zone(target_zone)]!</span>")
			return -1

		user.visible_message("<span class='notice'>[user] begins to insert [tool] into [target]'s [parse_zone(target_zone)].</span>",
			"<span class='notice'>You begin to insert [tool] into [target]'s [parse_zone(target_zone)]...</span>")

	else if(implement_type in implements_extract)
		current_type = "extract"
		var/list/organs = target.getorganszone(target_zone)
		if(!organs.len)
			to_chat(user, "<span class='notice'>There are no removable organs in [target]'s [parse_zone(target_zone)]!</span>")
			return -1
		else
			for(var/obj/item/organ/O in organs)
				O.on_find(user)
				organs -= O
				organs[O.name] = O

			I = input("Remove which organ?", "Surgery", null, null) as null|anything in organs
			if(I && user && target && user.Adjacent(target) && user.get_active_held_item() == tool)
				I = organs[I]
				if(!I) return -1
				user.visible_message("<span class='notice'>[user] begins to extract [I] from [target]'s [parse_zone(target_zone)].</span>",
					"<span class='notice'>You begin to extract [I] from [target]'s [parse_zone(target_zone)]...</span>")
			else
				return -1

	else if(implement_type in implements_mend)
		current_type = "mend"
		user.visible_message("<span class='notice'>[user] begins to [mend_the_incision] [target]'s [parse_zone(target_zone)].</span>",
			"<span class='notice'>You begin to [mend_the_incision] [target]'s [parse_zone(target_zone)]...</span>")

	else if(istype(tool, /obj/item/reagent_containers/food/snacks/organ))
		to_chat(user, "<span class='warning'>[tool] was bitten by someone! It's too damaged to use!</span>")
		return -1

/datum/surgery_step/manipulate_organs/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(current_type == "mend")
		user.visible_message("<span class='notice'>[user] [mends_the_incision] [target]'s [parse_zone(target_zone)].</span>",
			"<span class='notice'>You [mend_the_incision] [target]'s [parse_zone(target_zone)].</span>")
		if(locate(/datum/surgery_step/saw) in surgery.steps)
			target.heal_bodypart_damage(45,0)
		return 1

	else if(current_type == "posibrain")
		if(istype(tool, /obj/item/organ_storage))
			tool.icon_state = "evidenceobj"
			tool.desc = "A container for holding body parts."
			tool.cut_overlays()
			tool = tool.contents[1]

		user.temporarilyRemoveItemFromInventory(tool)
		spawn(1)
			I = new /obj/item/organ/brain/mmi_holder/posibrain(tool)
			I.Insert(target)
			user.visible_message("<span class='notice'>[user] inserts [tool] into [target]'s [parse_zone(target_zone)]!</span>",
				"<span class='notice'>You insert [tool] into [target]'s [parse_zone(target_zone)].</span>")

	else if(current_type == "insert")
		if(istype(tool, /obj/item/organ_storage))
			I = tool.contents[1]
			tool.icon_state = "evidenceobj"
			tool.desc = "A container for holding body parts."
			tool.cut_overlays()
			tool = I
		else
			I = tool
		user.drop_item()
		I.Insert(target)
		user.visible_message("<span class='notice'>[user] inserts [tool] into [target]'s [parse_zone(target_zone)]!</span>",
			"<span class='notice'>You insert [tool] into [target]'s [parse_zone(target_zone)].</span>")

	else if(current_type == "extract")
		if(I && I.owner == target)
			user.visible_message("<span class='notice'>[user] successfully extracts [I] from [target]'s [parse_zone(target_zone)]!</span>",
				"<span class='notice'>You successfully extract [I] from [target]'s [parse_zone(target_zone)].</span>")
			add_logs(user, target, "surgically removed [I.name] from", addition="INTENT: [uppertext(user.a_intent)]")
			I.Remove(target)
			I.loc = get_turf(target)
		else
			user.visible_message("<span class='notice'>[user] can't seem to extract anything from [target]'s [parse_zone(target_zone)]!</span>",
				"<span class='notice'>You can't extract anything from [target]'s [parse_zone(target_zone)]!</span>")
	return 0
