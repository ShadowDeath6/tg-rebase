/*
-emag level 1 = brain dmg //done //tested
-emag level 2 = flashing colors //done //tested
-125% brute dmg //done //tested
-150% shock dmg //done //tested
-cold and heat sensible //done //tested
-night vision if not hungry //done //tested
-feeds on power,gloves decresse and insulated prevent //done //tested
-fully augmented //done //tested
-weak to EMPS //done //tested
-teslium = meth but gives 200% dmg to shock //done //tested
-purge chem after a couple of seconds //done //tested
-oil heals burn at 2 per cycle //done //bugged
-welding fuel at 1 per cycle //done //bugged 


-implant insertion
-rad immunity
-virus resistant
-all virus are airborne
-special robot lansguage
*/

/datum/species/preternis
	name = "Preternis"
	id = "preternis"
	default_color = "FFFFFF"
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT
	inherent_traits = list(TRAIT_NOHUNGER)
	species_traits = list(EYECOLOR,HAIR,FACEHAIR,LIPS)
	say_mod = "intones"
	attack_verb = "assaults"
	meat = null
	toxic_food = NONE
	brutemod = 1.25
	burnmod = 1.5
	yogs_draw_robot_hair = TRUE
	mutanteyes = /obj/item/organ/eyes/preternis
	mutantlungs = /obj/item/organ/lungs/preternis

	var/charge = PRETERNIS_LEVEL_FULL
	var/eating_msg_cooldown = FALSE
	var/emag_lvl = 0
	var/power_drain = 0.3 //probably going to have to tweak this shit
	var/tesliumtrip = FALSE

/datum/species/preternis/on_species_gain(mob/living/carbon/C, datum/species/old_species, pref_load)
	. = ..()
	for (var/V in C.bodyparts)
		var/obj/item/bodypart/BP = V
		BP.change_bodypart_status(ORGAN_ROBOTIC,FALSE,TRUE)
		BP.burn_reduction = 0
		BP.brute_reduction = 0
		BP.max_damage = 35
	
/datum/species/preternis/on_species_loss(mob/living/carbon/human/C, datum/species/new_species, pref_load)
	. = ..()
	for (var/V in C.bodyparts)
		var/obj/item/bodypart/BP = V
		BP.change_bodypart_status(ORGAN_ORGANIC,FALSE,TRUE)
	C.clear_alert("preternis_emag")
	C.clear_fullscreen("preternis_emag")
	C.remove_movespeed_modifier("preternis_teslium")

/datum/species/preternis/spec_emp_act(mob/living/carbon/human/H, severity)
	. = ..()
	switch(severity)
		if(EMP_HEAVY)
			H.adjustBruteLoss(20)
			H.adjustFireLoss(20)
			H.Paralyze(50)
			charge *= 0.4
			H.visible_message("<span class='danger'>Electricity ripples over [H]'s subdermal implants, smoking profusely.</span>", \
							"<span class='userdanger'>A surge of searing pain erupts throughout your very being! As the pain subsides, a terrible sensation of emptiness is left in its wake.</span>")
		if(EMP_LIGHT)
			H.adjustBruteLoss(10)
			H.adjustFireLoss(10)
			H.Paralyze(20)
			charge *= 0.6
			H.visible_message("<span class='danger'>A faint fizzling emanates from [H].</span>", \
							"<span class='userdanger'>A fit of twitching overtakes you as your subdermal implants convulse violently from the electromagnetic disruption. Your sustenance reserves have been partially depleted from the blast.</span>")

/datum/species/preternis/spec_emag_act(mob/living/carbon/human/H, mob/user)
	. = ..()
	if(emag_lvl == 2)
		return
	emag_lvl = min(emag_lvl + 1,2)
	playsound(H.loc, 'sound/machines/warning-buzzer.ogg', 50, 1, 1)
	H.Paralyze(60)
	switch(emag_lvl)
		if(1)
			H.adjustBrainLoss(50) //HALP AM DUMB
			to_chat(H,"<span class='danger'>ALERT! MEMORY UNIT [rand(1,5)] FAILURE.NERVEOUS SYSTEM DAMAGE.</span>")
		if(2)
			H.overlay_fullscreen("preternis_emag", /obj/screen/fullscreen/high)
			H.throw_alert("preternis_emag", /obj/screen/alert/high/preternis)
			to_chat(H,"<span class='danger'>ALERT! OPTIC SENSORS FAILURE.VISION PROCESSOR COMPROMISED.</span>")

/datum/species/preternis/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	. = ..()

	if(H.reagents.has_reagent("oil"))
		H.adjustFireLoss(-2*REAGENTS_EFFECT_MULTIPLIER,FALSE,FALSE, 0)
		metabolize(chem,H)
		return TRUE

	if(H.reagents.has_reagent("welding_fuel"))
		H.adjustFireLoss(-1*REAGENTS_EFFECT_MULTIPLIER,FALSE,FALSE, 0)
		metabolize(chem,H)
		return TRUE

	if(H.reagents.has_reagent("teslium",10)) //10 u otherwise it wont update and they will remain quikk
		H.add_movespeed_modifier("preternis_teslium", update=TRUE, priority=101, multiplicative_slowdown=-2, blacklisted_movetypes=(FLYING|FLOATING))
		if(H.health < 50 && H.health > 0)
			H.adjustOxyLoss(-1*REAGENTS_EFFECT_MULTIPLIER)
			H.adjustBruteLoss(-1*REAGENTS_EFFECT_MULTIPLIER,FALSE,FALSE, 0)
			H.adjustFireLoss(-1*REAGENTS_EFFECT_MULTIPLIER,FALSE,FALSE, 0)
		H.AdjustParalyzed(-3)
		H.AdjustStun(-3)
		H.AdjustKnockdown(-3)
		H.adjustStaminaLoss(-5*REAGENTS_EFFECT_MULTIPLIER)
		charge -= 10 * REAGENTS_METABOLISM
		burnmod = 200
		tesliumtrip = TRUE
	else if(tesliumtrip)
		burnmod = initial(burnmod)
		tesliumtrip = FALSE
		H.remove_movespeed_modifier("preternis_teslium")

	if (istype(chem,/datum/reagent/consumable))
		var/datum/reagent/consumable/food = chem
		if (food.nutriment_factor)
			var/nutrition = food.nutriment_factor * 0.2
			adjust_charge(nutrition)
			if (!eating_msg_cooldown)
				eating_msg_cooldown = TRUE
				addtimer(VARSET_CALLBACK(src, eating_msg_cooldown, FALSE), 5 MINUTES)
				to_chat(H,"<span class='info'>NOTICE: Digestive subroutines are inefficient. Seek sustenance via power-cell C.O.N.S.U.M.E. technology induction.</span>")

	if(chem.current_cycle >= 20)
		H.reagents.del_reagent(chem.id)


	return FALSE

/datum/species/preternis/proc/metabolize(datum/reagent/chem,mob/living/carbon/human/H) //cant be assed to copy paste this everytime
	chem.current_cycle++
	H.reagents.remove_reagent(chem.id, chem.metabolization_rate * H.metabolism_efficiency)

/datum/species/preternis/spec_fully_heal(mob/living/carbon/human/H)
	. = ..()
	set_charge(PRETERNIS_LEVEL_FULL)
	emag_lvl = 0
	H.clear_alert("preternis_emag")
	H.clear_fullscreen("preternis_emag")
	burnmod = initial(burnmod)
	tesliumtrip = FALSE
	H.remove_movespeed_modifier("preternis_teslium") //full heal removes chems so it wont update the teslium speed up until they eat something

/datum/species/preternis/spec_life(mob/living/carbon/human/H)
	. = ..()
	handle_charge(H)

/datum/species/preternis/proc/adjust_charge(var/newchange)
	charge = CLAMP(charge + newchange, PRETERNIS_LEVEL_NONE, PRETERNIS_LEVEL_FULL)

/datum/species/preternis/proc/set_charge(var/newchange)
	charge = CLAMP(newchange, PRETERNIS_LEVEL_NONE, PRETERNIS_LEVEL_FULL)

/datum/species/preternis/proc/handle_charge(mob/living/carbon/human/H)
	adjust_charge(-power_drain)
	if(charge == PRETERNIS_LEVEL_NONE)
		to_chat(H,"<span class='danger'>Warning! System power criti-$#@$</span>")
		H.death()
	else if(charge < PRETERNIS_LEVEL_STARVING)
		H.throw_alert("preternis_charge", /obj/screen/alert/preternis_charge, 3)
	else if(charge < PRETERNIS_LEVEL_HUNGRY)
		H.throw_alert("preternis_charge", /obj/screen/alert/preternis_charge, 2)
	else if(charge < PRETERNIS_LEVEL_FED)
		H.throw_alert("preternis_charge", /obj/screen/alert/preternis_charge, 1)
	else
		H.clear_alert("preternis_charge")