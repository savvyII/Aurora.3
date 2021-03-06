/mob/living/carbon/proc/ingest(var/datum/reagents/from, var/datum/reagents/target, var/amount = 1, var/multiplier = 1, var/copy = 0) //we kind of 'sneak' a proc in here for ingesting stuff so we can play with it.
	if(last_taste_time + 50 < world.time)
		var/datum/reagents/temp = new(amount) //temporary holder used to analyse what gets transfered.
		from.trans_to_holder(temp, amount, multiplier, 1)

		var/text_output = temp.generate_taste_message(src)
		if(text_output != last_taste_text || last_taste_time + 100 < world.time) //We dont want to spam the same message over and over again at the person. Give it a bit of a buffer.
			to_chat(src, "<span class='notice'>You can taste [text_output]</span>")//no taste means there are too many tastes and not enough flavor.

			last_taste_time = world.time
			last_taste_text = text_output
	return from.trans_to_holder(target,amount,multiplier,copy) //complete transfer

/* what this does:
catalogue the 'taste strength' of each one
calculate text size per text.
*/
/datum/reagents/proc/generate_taste_message(mob/living/carbon/taster = null)
	var/minimum_percent = 15
	if(ishuman(taster))
		var/mob/living/carbon/human/H = taster
		minimum_percent = round(15/ (H.isSynthetic() ? TASTE_DULL : H.species.taste_sensitivity))

	var/list/out = list()
	var/list/tastes = list() //descriptor = strength
	if(minimum_percent <= 100)
		for(var/datum/reagent/R in reagent_list)
			if(!R.taste_mult)
				continue
			if(R.id == "nutriment" || R.id == "synnutriment") //this is ugly but apparently only nutriment (not subtypes) has taste data TODO figure out why
				var/list/taste_data = R.get_data()
				for(var/taste in taste_data)
					if(taste in tastes)
						tastes[taste] += taste_data[taste]
					else
						tastes[taste] = taste_data[taste]
			else
				var/taste_desc = R.taste_description
				var/taste_amount = get_reagent_amount(R.id) * R.taste_mult
				if(R.taste_description in tastes)
					tastes[taste_desc] += taste_amount
				else
					tastes[taste_desc] = taste_amount

		//deal with percentages
		var/total_taste = 0
		for(var/taste_desc in tastes)
			total_taste += tastes[taste_desc]
		for(var/taste_desc in tastes)
			var/percent = tastes[taste_desc]/total_taste * 100
			if(percent < minimum_percent)
				continue
			var/intensity_desc = "a hint of"
			if(percent > minimum_percent * 2 || percent == 100)
				intensity_desc = ""
			else if(percent > minimum_percent * 3)
				intensity_desc = "the strong flavor of"
			if(intensity_desc == "")
				out += "[taste_desc]"
			else
				out += "[intensity_desc] [taste_desc]"

	var/temp_text = ""

	switch(get_temperature())
		if(-INFINITY to T0C - 50)
			temp_text = "lethally freezing"
		if(T0C - 50 to T0C - 25)
			temp_text = "freezing"
		if(T0C - 25 to T0C - 10)
			temp_text = "very cold"
		if(T0C - 10 to T0C)
			temp_text = "cold"
		if(T0C to T0C + 15)
			temp_text = "cool"
		if(T0C + 15 to T0C + 25)
			temp_text = "lukewarm"
		if(T0C + 25 to T0C + 40)
			temp_text = "warm"
		if(T0C + 40 to T0C + 70)
			temp_text = "hot"
		if(T0C + 70 to T0C + 90)
			temp_text = "scolding hot"
		if(T0C + 90 to T0C + 120)
			temp_text = "burning hot"
		if(T0C + 120 to T0C + 150)
			temp_text = "molten hot"
		if(T0C + 150 to INFINITY)
			temp_text = "lethally hot"

	return "[temp_text] [english_list(out, "something indescribable")]."
