/obj/item/nutrient
	name = ""
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle16"
	flags = FPRINT |  TABLEPASS
	var/mutmod = 0
	var/yieldmod = 0

/obj/item/nutrient/ez
	name = "E-Z-Nutrient"
	icon_state = "bottle16"
	flags = FPRINT |  TABLEPASS
	mutmod = 1
	yieldmod = 1

/obj/item/nutrient/l4z
	name = "Left 4 Zed"
	icon_state = "bottle18"
	flags = FPRINT |  TABLEPASS
	mutmod = 2
	yieldmod = 0

/obj/item/nutrient/rh
	name = "Robust Harvest"
	icon_state = "bottle15"
	flags = FPRINT |  TABLEPASS
	mutmod = 0
	yieldmod = 2