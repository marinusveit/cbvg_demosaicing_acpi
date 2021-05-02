### A Pluto.jl notebook ###
# v0.14.4

using Markdown
using InteractiveUtils

# ╔═╡ 3d6aecaa-a47e-4197-9f87-d34533f488ca
# imports
begin
	import Pkg
	using Pkg
	Pkg.add("PlutoUI")
	Pkg.add("Images")
	Pkg.add("TestImages")
	Pkg.add("ImageTransformations")
	using ImageTransformations
	using TestImages
	using Images
	using PlutoUI
end

# ╔═╡ ffc27f40-1132-494f-87db-b1a7d0e0bf98


# ╔═╡ 5f647aac-e087-482a-af80-733fb387b73d
begin
	
	#    top_left 	top  				top_right
	# 	 left 		referenzpixel Pixel	right 	
	# 	 bottom_left bottom 			bottom_right
	#
	#
#	top_left = (1, -1) # z. B. ein zeile und ein spalte vor dem pixel das man betrachtet
#	top = (+1, 0)
#	top_right = (1, 1)
#	left = (0, -1)
#	current = (0, 0)
#	right = (0, 1)
#	bottom_left = (-1, -1)
#	bottom = (-1, 0)
#	bottom_right = (-1, 1)
#	left_left = (0, -2)
#	top_top = (2, 0)
#	bottom_bottom = (-2, 0)
#	right_right = (0, 2)
	top_left = (-1, -1) # z. B. ein zeile und ein spalte vor dem pixel das man betrachtet
	top = (-1, 0)
	top_right = (-1, 1)
	left = (0, -1)
	current = (0, 0)
	right = (0, 1)
	bottom_left = (1, -1)
	bottom = (1, 0)
	bottom_right = (1, 1)
	left_left = (0, -2)
	top_top = (-2, 0)
	bottom_bottom = (2, 0)
	right_right = (0, 2)
	
	# funktionen zum extrahieren des blau, grün oder rot anteils einer rgb farbe
	function green_value(color)
		return RGB(0, color.g, 0)
	end
	function red_value(color)
		return RGB(color.r, 0, 0)
	end
	function blue_value(color)
		return RGB(0, 0, color.b)
	end
	# convertiert N0fb zu Float32
	function conv(n0fb)
		return convert(Float32, n0fb)
	end
	# funktion die den Kopf von Luigi extrahiert
	function head(image, resize)
		(height, width) = size(image)
		head = image[1:trunc(Int, height ÷ 2), trunc(Int, width ÷ 7):trunc(Int, width-6)]
		return imresize(head, ratio=resize)
		#return imresize(head, size(head).*resize)
	end
	
	"""
	    sum_color(
	
	
	"""
	function sum_red_channel(image, current_pixel_position::Tuple{Int64, Int64}, pixel_coordinates::Tuple{Int64, Int64}...)
		result = 0.0
		for param in pixel_coordinates # firstindex()+2:lastindex()
			result += convert(Float32, image[current_pixel_position[1] + param[1], 
											 current_pixel_position[2] + param[2]].r)
		end
		return result
	end
	
	function sum_green_channel(image, current_pixel_position::Tuple{Int64, Int64}, pixel_coordinates::Tuple{Int64, Int64}...)
		result = 0.0
		for param in pixel_coordinates # firstindex()+2:lastindex()
			result += convert(Float32, image[current_pixel_position[1] + param[1], 
											 current_pixel_position[2] + param[2]].g)
		end
		return result
	end
	
	function sum_blue_channel(image, current_pixel_position::Tuple{Int64, Int64}, pixel_coordinates::Tuple{Int64, Int64}...)
		result = 0.0
		for param in pixel_coordinates # firstindex()+2:lastindex()
			result += convert(Float32, image[current_pixel_position[1] + param[1], 
											 current_pixel_position[2] + param[2]].b)
		end
		return result
	end
	
	# funktionen überladen, dass man auch negative zahlen addieren kann und faktor vor der zahl hat
	function sum_red_channel(image, current_pixel_position::Tuple{Int64, Int64}, pixel_coordinates::Tuple{Tuple{Int64, Int64}, Number}...)
		result = 0.0
		for param in pixel_coordinates # firstindex()+2:lastindex()
			result += convert(Float32, image[current_pixel_position[1] + param[1][1], 
											 current_pixel_position[2] + param[1][2]].r) * param[2][1]
		end
		return result
	end
	
	function sum_green_channel(image, current_pixel_position::Tuple{Int64, Int64}, pixel_coordinates::Tuple{Tuple{Int64, Int64}, Number}...)
		result = 0.0
		for param in pixel_coordinates # firstindex()+2:lastindex()
			result += convert(Float32, image[current_pixel_position[1] + param[1][1], 
											 current_pixel_position[2] + param[1][2]].g) * param[2][1]
		end
		return result
	end
	
	# pixel_coordinates::Tuple{Tuple{Int64, Int64}, Int64}: ((zeile, spalte), vorfaktor)
	function sum_blue_channel(image, current_pixel_position::Tuple{Int64, Int64}, pixel_coordinates::Tuple{Tuple{Int64, Int64}, Number}...)
		result = 0.0
		for param in pixel_coordinates # firstindex()+2:lastindex()
			result += convert(Float32, image[current_pixel_position[1] + param[1][1], 
											 current_pixel_position[2] + param[1][2]].b) * param[2][1]
		end
		return result
	end

end

# ╔═╡ 3c795e2c-b078-485b-b579-8fe3c0e22db0
begin
	typeof((1,1))
	RGB(0,0,0).b
	typeof(0.0)
	a = (1, 1)
	a[1]
	((1,2),3)[2][1]
end

# ╔═╡ bfa6f004-e3ab-4363-ab76-b14de80b272a
html"""<style>
main {
    max-width: 1200px;
}
"""

# ╔═╡ ef83b17c-b66c-4734-aebe-6a6d9390b914
# greenchannel.sum(bayerfilter, bottomright, top, left, current)
begin
	function blue_bilin_interpol(bayer_filter, row, column)
		return sum_blue_channel(bayer_filter, (row, column), top_left, top_right,  bottom_left, bottom_right) / 4
	end
	
	function green_bilin_interpol(bayer_filter, row, column)
		return sum_green_channel(bayer_filter, (row, column), left, right, bottom, top) / 4
	end
	
	function red_bilin_interpol(bayer_filter, row, column)
		return sum_red_channel(bayer_filter, (row, column), bottom_left, bottom_right, top_right, top_left) / 4
	end
	
	function red_bilin_interpol_vertical(bayer_filter, row, column)
		return sum_red_channel(bayer_filter, (row, column), top, bottom) / 2
	end
	
	function red_bilin_interpol_horizontal(bayer_filter, row, column)
		return sum_red_channel(bayer_filter, (row, column), left, right) / 2
	end
	
	function blue_bilin_interpol_vertical(bayer_filter, row, column)
		return sum_blue_channel(bayer_filter, (row, column), bottom, top) / 2
	end
	
	function blue_bilin_interpol_horizontal(bayer_filter, row, column)
		return sum_blue_channel(bayer_filter, (row, column), left, right) / 2
	end
end

# ╔═╡ 429b0bc0-4e24-48b6-807d-08bb5f39aae2
# Indexe der hotpixel bestimmen
begin
	# versuchen die grünpixel
	function green_red_hotpixels(image)
		(height, width) = size(image)
		return [(row, column) for column=3:2:width-2, row=3:2:height-2]
	end
	function redhotpixels(image)
		(height, width) = size(image)
		return [(row, column) for column=4:2:width-2, row=3:2:height-2]
	end

	function bluehotpixels(image)
		(height, width) = size(image)
		return [(row, column) for column=3:2:width-2, row=4:2:height-2]
	end
	function green_blue_hotpixels(image)
		(height, width) = size(image)
		return [(row,column) for column=4:2:width-2, row=4:2:height-2]
	end

end

# ╔═╡ 39502556-161a-4efc-864b-fcf1755db8a4

function bayer_colorfilter(image)
	bayer_filter = copy(image)
	# an diesen stellen nur grüne hotpixel => nur grünwert setzen. analog dazu die anderen farbwerte der hotpixel setzen
	for (row, column) in green_red_hotpixels(image)
		bayer_filter[row, column] = green_value(image[row, column])
	end
	# rote hotpixel
	for (row, column) in redhotpixels(image)
		bayer_filter[row, column] = red_value(image[row, column])
	end
	
	# blaue hotpixel
	for (row, column) in bluehotpixels(image)
		bayer_filter[row, column] = blue_value(image[row, column])
	end
	# grüne hotpixel
	for (row, column) in green_blue_hotpixels(image)
		bayer_filter[row, column] = green_value(image[row, column])
	end

	return bayer_filter
end

# ╔═╡ c9f06538-02ec-4dd5-a915-0140741b041f
# ohne randbetrachtung (randpixel bleiben noch unverändert)
function bilineare_interpolation(bayer_filter)
	(height, width) = size(bayer_filter)
	bilin_interpol = copy(bayer_filter)
	
	# ungerade Bildzeilen
	# grüner hotpixel 
	for (row, column) in green_red_hotpixels(bayer_filter)
		blue = blue_bilin_interpol_vertical(bayer_filter, row, column)
		red = red_bilin_interpol_horizontal(bayer_filter, row, column)
		bilin_interpol[row, column] = RGB(red, bayer_filter[row, column].g, blue)			
	end
	
	# roter pixel
	for (row, column) in redhotpixels(bayer_filter)
		blue = blue_bilin_interpol(bayer_filter, row, column)
		green = green_bilin_interpol(bayer_filter, row, column)
		bilin_interpol[row, column] = RGB(bayer_filter[row, column].r, green, blue)
	end
	
	# gerade Bildzeilen
	# blauer pixel
	for (row, column) in bluehotpixels(bayer_filter)
		red = red_bilin_interpol(bayer_filter, row, column)
		green = green_bilin_interpol(bayer_filter, row, column)
		bilin_interpol[row, column] = RGB(red, green, bayer_filter[row, column].b)
	end
	# grüner pixel
	for (row, column) in green_blue_hotpixels(bayer_filter)
		blue = blue_bilin_interpol_horizontal(bayer_filter, row, column)
		red = red_bilin_interpol_vertical(bayer_filter, row, column)
		bilin_interpol[row, column] = RGB(red, bayer_filter[row, column].g, blue)
	end
	return bilin_interpol
end

# ╔═╡ 92c26370-a774-11eb-163a-3b4671b8c14b
begin
	url = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/49c5b1cb-dc91-4d68-8aad-91b7c444aa77/dbpsnv9-68a6a080-4136-479d-bf58-ab38ebfad2e6.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcLzQ5YzViMWNiLWRjOTEtNGQ2OC04YWFkLTkxYjdjNDQ0YWE3N1wvZGJwc252OS02OGE2YTA4MC00MTM2LTQ3OWQtYmY1OC1hYjM4ZWJmYWQyZTYuanBnIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.CiJ9jFsCBqlWUjSjMX9WHJEK-D7vpHHEi82oaI-44LI"

	download(url, "pixel_luigi.jpg")
end

# ╔═╡ a136aaaf-d467-40fa-8fff-ad9817148e6c
begin
	luigi = load("pixel_luigi.jpg")
end

# ╔═╡ e5530339-75e8-4441-9e7a-0f9356c217da
begin
	bayer_luigi = bayer_colorfilter(luigi)
end

# ╔═╡ 02474a45-4503-4186-a29b-44a24fd112fd
sum_green_channel(bayer_luigi, (3, 2),  (bottom, -2.5), (bottom, 5))

# ╔═╡ 1be3ace0-de06-4bd1-9d31-baaa9b154b18
begin
	luigis_head = head(luigi, 2)
	luigi_b_head = head(bayer_luigi, 2)
	[luigis_head luigi_b_head]
end

# ╔═╡ 8c1b7413-9b9e-44d0-9701-ade1fd3de536
bayer_luigi[1:10,1:10]

# ╔═╡ 1746ff45-7bae-4033-bec9-477ecfb47bd5
luigi_bilineare_interpolation = bilineare_interpolation(bayer_luigi)

# ╔═╡ 1c9abcb1-8396-41f4-9dad-97a1e1e0aa4f


# ╔═╡ 5e2302ad-2e33-4788-9ea9-0a44b9603b5c
hcat(luigi, bayer_luigi,luigi_bilineare_interpolation)

# ╔═╡ b89fb2e2-a3cd-44e7-942a-b09c51deee18
begin
	bi_lin_head = head(luigi_bilineare_interpolation, 2)
	[luigis_head bi_lin_head]
end

# ╔═╡ 826b8cc7-e2fb-4217-9737-0fa7119dca8d
function hqlin(bayer_filter)
	hqlin = copy(bayer_filter)
	(height, width) = size(bayer_filter)
	
	# Bildzeilen, in denen nur grüne und rote hotpixel sind
	for (row, column) in green_red_hotpixels(bayer_filter)
		# grünes hotpixel
		# 1. rotwert bestimmen
		# 1.1 bilineare interpolation
		red = red_bilin_interpol_horizontal(bayer_filter, row, column)
		# 1.2 vertikalen Laplace-Anteil addieren
		red += sum_green_channel(bayer_filter, (row, column), (top_left, -1), (top_top, 0.5), (top_right, -1),
															  (left_left, -1), (current, 5), (right_right, -1), 																	 						  (bottom_left, -1), (bottom_bottom, 0.5), (bottom_right, -1)) / 8
		# 1. blauwert bestimmen
		# 1.1 bilineare interpolation
		blue = blue_bilin_interpol_vertical(bayer_filter, row, column)
		# 1.2 horizontalen Laplace-Anteil addieren
		blue += sum_green_channel(bayer_filter, (row, column), (top_left, -1), (top_top, -1), (top_right, -1),
															  (left_left, 0.5), (current, 5), (right_right, 0.5), 																	 						  (bottom_left, -1), (bottom_bottom, -1), (bottom_right, -1)) / 8
		# werte zwischen 0 und 1 beschränken
		red = clamp(red, 0.0, 1.0)
		blue = clamp(blue, 0.0, 1.0)
		hqlin[row, column] = RGB(red, bayer_filter[row, column].g, blue)
	end
		# rotes hotpixel
	for (row, column) in redhotpixels(bayer_filter)
		# 1. blauwerte bestimmen
		# 1.1 bilineare interpolation
		blue = blue_bilin_interpol(bayer_filter, row, column)
		# 1.2 Laplace-Anteil addieren
		blue += 1.5 * sum_red_channel(bayer_filter, (row, column), 				(top_top, -1),
															  (left_left, -1),  (current, 4), 		(right_right, -1), 																	 						  				(bottom_bottom, -1) 					) / 8
		# 2 grünwerte bestimmen
		# 2.1 bilineare interpolation
		green = green_bilin_interpol(bayer_filter, row, column)
		# 2.2 Laplace-Anteil addieren
		green += sum_red_channel(bayer_filter, (row, column), 					(top_top, -1),
															  (left_left, -1),  (current, 4), 		(right_right, -1), 																	 						  				(bottom_bottom, -1) 					) / 8
		# werte nur noch zwischen 0 und 1
		green = clamp(green, 0.0, 1.0)
		blue = clamp(blue, 0.0, 1.0)
		hqlin[row, column] = RGB(bayer_filter[row, column].r, green, blue)
	end
	
	# geraden Bildzeilen
		# blaues hotpixel
	for (row, column) in bluehotpixels(bayer_filter)
		# 1. rotwerte bestimmen
		# 1.1 bilineare interpolation
		red = red_bilin_interpol(bayer_filter, row, column)
		# 1.2 Laplace-Anteil addieren
		red += 1.5* sum_blue_channel(bayer_filter, (row, column), 					(top_top, -1),
															  	  (left_left, -1),  (current, 4), 		(right_right, -1), 																	 						  				(bottom_bottom, -1) 				) / 8
		# 2 grünwerte bestimmen
		# 2.1 bilineare interpolation
		green = green_bilin_interpol(bayer_filter, row, column)
		# 2.2 Laplace-Anteil addieren
		green += sum_blue_channel(bayer_filter, (row, column), 					(top_top, -1),
															  (left_left, -1),  (current, 4), 		(right_right, -1), 																	 						  				(bottom_bottom, -1) 				) / 8
			
		green = clamp(green, 0.0, 1.0)
		red = clamp(red, 0.0, 1.0)
		hqlin[row, column] = RGB(red, green, bayer_filter[row, column].b)
	end
		# grünes hotpixel
	for (row, column) in green_blue_hotpixels(bayer_filter)
		# 1. rotwert bestimmen
		# 1.1 bilineare interpolation
		red = red_bilin_interpol_vertical(bayer_filter, row, column)
		# 1.2 horizontalen Laplace-Anteil addieren
		red += sum_green_channel(bayer_filter, (row, column), (top_left, -1), (top_top, -1), (top_right, -1),
															  (left_left, 0.5), (current, 5), (right_right, 0.5), 																	 						  (bottom_left, -1), (bottom_bottom, -1), (bottom_right, -1)) / 8
		# 1. blauwert bestimmen
		# 1.1 bilineare interpolation
		blue = blue_bilin_interpol_horizontal(bayer_filter, row, column)
		# 1.2 Laplace-Anteil addieren
		blue += sum_green_channel(bayer_filter, (row, column), (top_left, -1), (top_top, 0.5), (top_right, -1),
															  (left_left, -1), (current, 5), (right_right, -1), 																	 						  (bottom_left, -1), (bottom_bottom, 0.5), (bottom_right, -1)) / 8
		# werte zwischen 0 und 1 beschränken
		red = clamp(red, 0.0, 1.0)
		blue = clamp(blue, 0.0, 1.0)
		hqlin[row, column] = RGB(red, bayer_filter[row, column].g, blue)
	end
	
	return hqlin
end

# ╔═╡ 8db7f71e-0bcc-40c1-be67-7177b251ddae
luigi_hqlin = hqlin(bayer_luigi)

# ╔═╡ 2b67027a-77a0-40c0-9afc-f52da41d9b2b
begin
	compare_images = [luigi luigi_bilineare_interpolation luigi_hqlin]
	imresize(compare_images, ratio=5)
end

# ╔═╡ d4e7a7f1-929c-4be7-943d-4267cedacfc2


# ╔═╡ 48e4ae5d-5423-442c-9b4e-712f42b84bc2
function acpi_green_channel(bayer_filter)
	acpi_green_channel = copy(bayer_filter)

	# rotes hotpixel
	for (row, column) in redhotpixels(bayer_filter)
		# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
		# 1.1 horizontaler gradient
		g_horizontal = abs(sum_green_channel(bayer_filter, (row, column), (left, 1), (right, -1))) + abs(sum_red_channel(bayer_filter, (row, column), (left_left, -1), (current, 2), (right_right, -1)))
		# 1.2 vertikaler gradient
		g_vertical = abs(sum_green_channel(bayer_filter, (row, column), (top, 1), (bottom, -1))) + abs(sum_red_channel(bayer_filter, (row, column), (top_top, -1), (current, 2), (bottom_bottom, -1)))
		
		# horizontaler gradient größer => vertikale kante => vertikale grünwerte für berechnung sinnvoller, da hier keine großen farbänderungen sind
		green = 0
		if g_vertical > g_horizontal
			# horizontale bilineare interpolation
			green = 0.5 * sum_green_channel(bayer_filter, (row, column), left, right)
			# horizontalen Laplace Anteil addieren
			green += 0.25 * sum_red_channel(bayer_filter, (row, column), (left_left, -1), (current, 2), (right_right, -1))
		else
			# vertikale bilineare interpolation
			green = 0.5 * sum_green_channel(bayer_filter, (row, column), top, bottom)
			# vertikalen Laplace-Anteil addieren
			green += 0.25 * sum_red_channel(bayer_filter, (row, column), (top_top, -1), (current, 2), (bottom_bottom, -1))
		end
		
		# grünwert zum rekonstruieren des grünkanals setzen
		green = clamp(green, 0.0, 1.0)
		acpi_green_channel[row, column] = RGB(bayer_filter[row, column].r, green, 0)
	end
	
	# blaues hotpixel
	for (row, column) in bluehotpixels(bayer_filter)
		# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
		# 1.1 horizontaler gradient
		g_horizontal = abs(sum_green_channel(bayer_filter, (row, column), (left, 1), (right, -1))) + abs(sum_blue_channel(bayer_filter, (row, column), (left_left, -1), (current, 2), (right_right, -1)))
		# 1.2 vertikaler gradient
		g_vertical = abs(sum_green_channel(bayer_filter, (row, column), (bottom, 1), (top, -1))) + abs(sum_blue_channel(bayer_filter, (row, column), (bottom_bottom, -1), (current, 2), (top_top, -1)))
		
		# 2. grünwerte bestimmen
		# horizontaler gradient größer => vertikale kante => vertikale grünwerte für berechnung sinnvoller, da hier keine großen farbänderungen sind
		green = 0
		if g_vertical > g_horizontal
			# horizontale bilineare interpolation
			green = 0.5 * sum_green_channel(bayer_filter, (row, column), (left, 1), (right, -1))
			# horizontalen Laplace Anteil addieren
			green += 0.25 * sum_blue_channel(bayer_filter, (row, column), (left_left, -1), (current, 2), (right_right, -1))
		else
			# vertikale bilineare interpolation
			
			green = 0.5 * sum_green_channel(bayer_filter, (row, column), top, bottom)
			# vertikalen Laplace-Anteil addieren
			green += 0.25 * sum_blue_channel(bayer_filter, (row, column), (top_top, -1), (current, 2), (bottom_bottom, -1))
		end
		# grünwert zum rekonstruieren des grünkanals setzen
		green = clamp(green, 0.0, 1.0)
		acpi_green_channel[row, column] = RGB(0, green, bayer_filter[row, column].b)
	end
	return acpi_green_channel
end

# ╔═╡ c00ec842-85a5-4554-94ce-628f28d34b09
begin
	acpi_green_luigi = acpi_green_channel(bayer_luigi)
	[bayer_luigi acpi_green_luigi]
end

# ╔═╡ 211756ce-1b62-491b-9914-a82cfdb663fa
# warum dieser name '.._red_..(acpi_green_channel)'??
function acpi_red_green(acpi_green_channel, bayer_filter)
	acpi = copy(acpi_green_channel)
	(height, width) = size(acpi_green_channel)

	# grünes hotpixel
	for (row, column) in green_red_hotpixels(acpi_green_channel)
		red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), left, right) + 0.5 * sum_green_channel(acpi_green_channel, (row, column), (left, -1), (current, 2), (right, -1))
		blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), bottom, top) + 0.5 * sum_green_channel(acpi_green_channel, (row, column), (bottom, -1), (current, 2), (top, -1))
		
		# nur noch werte zwischen 0 und 1
		red = clamp(red, 0.0, 1.0)
		blue = clamp(blue, 0.0, 1.0)
		acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, blue)
	end
	
	# rotes hotpixel
	for (row, column) in redhotpixels(acpi_green_channel)
		# rekonstruieren des blaukanals
		# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
		# 1.1 diagonal negativer gradient (links oben nach rechts unten)
		g_neg = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_left, 1), (bottom_right, -1))) + abs(sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1)))
		# 1.2 diagonal positiver gradient (rechts oben nach links unten)
		g_pos = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_right, 1), (bottom_left, -1))) + abs(sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1)))
		
		# diagonal negativer gradient größer => diagonal positive grünwerte für berechnung sinnvoller
		if g_neg > g_pos # TODO: prüfen ob buch hier falsch liegt
			blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), (top_left, -1), (bottom_right, -1))
			blue += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1))
		else
			blue = sum_blue_channel(acpi_green_channel, (row, column), (top_right, 1), (bottom_left, -1))
			blue += sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1))
		end
			# nur noch werte zwischen 0 und 1 
		blue = clamp(blue, 0.0, 1.0)
		acpi[row, column] = RGB(acpi_green_channel[row, column].r, acpi_green_channel[row, column].g, blue)
	end
	
	# geraden Bildzeilen
	# blaues hotpixel
	for (row, column) in bluehotpixels(acpi_green_channel)
		# rekonstruieren des blaukanals
		# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
		# 1.1 diagonal negativer gradient (links oben nach rechts unten)
		# TODO: wird auch in red benötigt => auslagern
		g_neg = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_left, 1), (bottom_right, -1))) + abs(sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1)))
		# 1.2 diagonal positiver gradient (links oben nach rechts unten)
		g_pos = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_right, 1), (bottom_left, -1))) + abs(sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1)))
		
		# diagonal negativer gradient größer => diagonal positive grünwerte für berechnung sinnvoller
		if g_neg > g_pos # TODO: prüfen ob buch hier falsch liegt
			red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), (top_left, -1), (bottom_right, -1))
			red += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1))
		else
			red = sum_red_channel(acpi_green_channel, (row, column), (top_right, 1), (bottom_left, -1))
			red += sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1))
		end
		# nur noch werte zwischen 0 und 1 
		red = clamp(red, 0.0, 1.0)
		acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, acpi_green_channel[row, column].b)
	end
		
	# grünes hotpixel
	for (row, column) in green_blue_hotpixels(acpi_green_channel)
		red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), bottom, top) + 0.5 * sum_green_channel(acpi_green_channel, (row, column), (bottom, -1), (current, 2), (top, -1))
		blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), left, right) + 0.5 * sum_green_channel(acpi_green_channel, (row, column), (left, -1), (current, 2), (right, -1))
		
		# nur noch werte zwischen 0 und 1
		red = clamp(red, 0.0, 1.0)
		blue = clamp(blue, 0.0, 1.0)
		acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, blue)
	end
	return acpi
end

# ╔═╡ bc8381e8-94ea-48a9-8897-61eb5826fae9
function acpi(bayer_filter)
	green_channel = acpi_green_channel(bayer_filter)
	return acpi_red_green(green_channel, bayer_filter)
end

# ╔═╡ 6b76b17f-0328-4b35-90ba-b149b61cb63c
begin
	acpi_luigi = acpi(bayer_luigi)
	tmp = [luigi bayer_luigi acpi_green_luigi acpi_luigi]
	imresize(tmp, ratio=5)
end

# ╔═╡ Cell order:
# ╠═3d6aecaa-a47e-4197-9f87-d34533f488ca
# ╠═ffc27f40-1132-494f-87db-b1a7d0e0bf98
# ╠═5f647aac-e087-482a-af80-733fb387b73d
# ╠═3c795e2c-b078-485b-b579-8fe3c0e22db0
# ╠═02474a45-4503-4186-a29b-44a24fd112fd
# ╠═bfa6f004-e3ab-4363-ab76-b14de80b272a
# ╠═ef83b17c-b66c-4734-aebe-6a6d9390b914
# ╠═429b0bc0-4e24-48b6-807d-08bb5f39aae2
# ╠═39502556-161a-4efc-864b-fcf1755db8a4
# ╠═c9f06538-02ec-4dd5-a915-0140741b041f
# ╠═92c26370-a774-11eb-163a-3b4671b8c14b
# ╠═a136aaaf-d467-40fa-8fff-ad9817148e6c
# ╠═e5530339-75e8-4441-9e7a-0f9356c217da
# ╠═1be3ace0-de06-4bd1-9d31-baaa9b154b18
# ╠═8c1b7413-9b9e-44d0-9701-ade1fd3de536
# ╠═1746ff45-7bae-4033-bec9-477ecfb47bd5
# ╠═1c9abcb1-8396-41f4-9dad-97a1e1e0aa4f
# ╠═5e2302ad-2e33-4788-9ea9-0a44b9603b5c
# ╠═b89fb2e2-a3cd-44e7-942a-b09c51deee18
# ╠═826b8cc7-e2fb-4217-9737-0fa7119dca8d
# ╠═8db7f71e-0bcc-40c1-be67-7177b251ddae
# ╠═2b67027a-77a0-40c0-9afc-f52da41d9b2b
# ╠═d4e7a7f1-929c-4be7-943d-4267cedacfc2
# ╠═48e4ae5d-5423-442c-9b4e-712f42b84bc2
# ╠═c00ec842-85a5-4554-94ce-628f28d34b09
# ╠═211756ce-1b62-491b-9914-a82cfdb663fa
# ╠═bc8381e8-94ea-48a9-8897-61eb5826fae9
# ╠═6b76b17f-0328-4b35-90ba-b149b61cb63c
