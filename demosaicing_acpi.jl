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

# ╔═╡ 5f647aac-e087-482a-af80-733fb387b73d
begin
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
end

# ╔═╡ bfa6f004-e3ab-4363-ab76-b14de80b272a
html"""<style>
main {
    max-width: 1000px;
}
"""

# ╔═╡ ef83b17c-b66c-4734-aebe-6a6d9390b914
begin
	function blue_bilin_interpol(bayer_filter, row, column)
		return (conv(bayer_filter[row-1, column-1].b) + conv(bayer_filter[row-1, column+1].b) + conv(bayer_filter[row+1, column+1].b) + conv(bayer_filter[row+1, column-1].b)) / 4
	end
	
	function green_bilin_interpol(bayer_filter, row, column)
		return (conv(bayer_filter[row, column-1].g) + conv(bayer_filter[row, column+1].g) + conv(bayer_filter[row-1, column].g) + conv(bayer_filter[row+1, column].g)) / 4
	end
	
	function red_bilin_interpol(bayer_filter, row, column)
		return (conv(bayer_filter[row-1, column-1].r) + conv(bayer_filter[row-1, column+1].r) + conv(bayer_filter[row+1, column+1].r) + conv(bayer_filter[row+1, column-1].r)) / 4
	end
	
	function red_bilin_interpol_vertical(bayer_filter, row, column)
		return (conv(bayer_filter[row-1, column].r) + conv(bayer_filter[row+1, column].r)) / 2
	end
	
	function red_bilin_interpol_horizontal(bayer_filter, row, column)
		return (conv(bayer_filter[row, column-1].r) + conv(bayer_filter[row, column+1].r)) / 2
	end
	
	function blue_bilin_interpol_vertical(bayer_filter, row, column)
		return (conv(bayer_filter[row-1, column].b) + conv(bayer_filter[row+1, column].b)) / 2
	end
	
	function blue_bilin_interpol_horizontal(bayer_filter, row, column)
		return (conv(bayer_filter[row, column-1].b) + conv(bayer_filter[row, column+1].b)) / 2
	end
end

# ╔═╡ 39502556-161a-4efc-864b-fcf1755db8a4

function bayer_colorfilter(image)
	bayer_filter = copy(image)
	(height, width) = size(image)
	# ungeraden Bildzeilen
	for image_row in 1:2:height
		# in ungeraden Bildspalten die grünwerte abtasten
		for image_column in 1:2:width
			bayer_filter[image_row, image_column] = green_value(image[image_row, image_column])
		end
		# in geraden Bildspalten die rotwerte abtasten
		for image_column in 2:2:width
			bayer_filter[image_row, image_column] = red_value(image[image_row, image_column])
		end
	end
	
	# geraden Bildzeilen
	for image_row in 2:2:height
		# in ungeraden Bildspalten die blauwerte abtasten
		for image_column in 1:2:width
			bayer_filter[image_row, image_column] = blue_value(image[image_row, image_column])
		end
		# in geraden Bildspalten die grünwerte abtasten
		for image_column in 2:2:width
			bayer_filter[image_row, image_column] = green_value(image[image_row, image_column])
		end
	end
	
	return bayer_filter
end

# ╔═╡ c9f06538-02ec-4dd5-a915-0140741b041f
# ohne randbetrachtung (randpixel bleiben noch unverändert)
function bilineare_interpolation(bayer_filter)
	(height, width) = size(bayer_filter)
	bilin_interpol = copy(bayer_filter)
		# 
	for image_row in 3:2:height-1
		# grüner pixel
		for image_column in 3:2:width-1
			blue = blue_bilin_interpol_vertical(bayer_filter, image_row, image_column)
			red = red_bilin_interpol_horizontal(bayer_filter, image_row, image_column)
			bilin_interpol[image_row, image_column] = RGB(red, bayer_filter[image_row, image_column].g, blue)			
		end
		# roter pixel
		for image_column in 2:2:width-1
			blue = blue_bilin_interpol(bayer_filter, image_row, image_column)
			green = green_bilin_interpol(bayer_filter, image_row, image_column)
			bilin_interpol[image_row, image_column] = RGB(bayer_filter[image_row, image_column].r, green, blue)
		end
	end
	
	# geraden Bildzeilen
	for image_row in 2:2:height-1
		# blauer pixel
		for image_column in 3:2:width-1
			red = red_bilin_interpol(bayer_filter, image_row, image_column)
			green = green_bilin_interpol(bayer_filter, image_row, image_column)
			bilin_interpol[image_row, image_column] = RGB(red, green, bayer_filter[image_row, image_column].b)
		end
		# grüner pixel
		for image_column in 2:2:width-1
			blue = blue_bilin_interpol_horizontal(bayer_filter, image_row, image_column)
			red = red_bilin_interpol_vertical(bayer_filter, image_row, image_column)
			bilin_interpol[image_row, image_column] = RGB(red, bayer_filter[image_row, image_column].g, blue)
		end
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

# ╔═╡ 5be0f1f9-e4f5-4c17-81c4-258cf400ff87
bayer_luigi = bayer_colorfilter(luigi)

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
	for row in 3:2:height-2
		# grünes hotpixel
		for column in 3:2:width-2
			# 1. rotwert bestimmen
			# 1.1 bilineare interpolation
			red = red_bilin_interpol_horizontal(bayer_filter, row, column)
			# 1.2 Laplace-Anteil addieren
			red += (5*conv(bayer_filter[row, column].g) - conv(bayer_filter[row, column-2].g) - conv(bayer_filter[row, column+2].g) - conv(bayer_filter[row-1, column-1].g) - conv(bayer_filter[row+1, column+1].g) - conv(bayer_filter[row+1, column-1].g) - conv(bayer_filter[row-1, column+1].g) + 0.5 * conv(bayer_filter[row-2, column].g) + conv(bayer_filter[row+2, column].g)) / 8
			# 1. blauwert bestimmen
			# 1.1 bilineare interpolation
			blue = blue_bilin_interpol_vertical(bayer_filter, row, column)
			# 1.2 Laplace-Anteil addieren
			blue += (5*conv(bayer_filter[row, column].g) - conv(bayer_filter[row-2, column].g) - conv(bayer_filter[row+2, column].g) - conv(bayer_filter[row-1, column-1].g) - conv(bayer_filter[row+1, column+1].g) - conv(bayer_filter[row+1, column-1].g) - conv(bayer_filter[row-1, column+1].g) + 0.5 * conv(bayer_filter[row, column-2].g) + conv(bayer_filter[row, column+2].g)) / 8
			# werte zwischen 0 und 1 beschränken
			red = clamp(red, 0.0, 1.0)
			blue = clamp(blue, 0.0, 1.0)
			hqlin[row, column] = RGB(red, bayer_filter[row, column].g, blue)
		end
		# rotes hotpixel
		for column in 4:2:width-2
			# 1. blauwerte bestimmen
			# 1.1 bilineare interpolation
			blue = blue_bilin_interpol(bayer_filter, row, column)
			# 1.2 Laplace-Anteil addieren
			blue += 1.5*(4*conv(bayer_filter[row, column].r) - conv(bayer_filter[row-2, column].r) - conv(bayer_filter[row, column-2].r) - conv(bayer_filter[row+2, column].r) - conv(bayer_filter[row, column+2].r)) / 8
			# 2 grünwerte bestimmen
			# 2.1 bilineare interpolation
			green = green_bilin_interpol(bayer_filter, row, column)
			# 2.2 Laplace-Anteil addieren
			green += (4*conv(bayer_filter[row, column].r) - conv(bayer_filter[row-2, column].r) - conv(bayer_filter[row, column-2].r) - conv(bayer_filter[row+2, column].r) - conv(bayer_filter[row, column+2].r)) / 8
			# werte nur noch zwischen 0 und 1
			green = clamp(green, 0.0, 1.0)
			blue = clamp(blue, 0.0, 1.0)
			hqlin[row, column] = RGB(bayer_filter[row, column].r, green, blue)
		end
	end
	
	# geraden Bildzeilen
	for row in 4:2:height-2
		# blaues hotpixel
		for column in 3:2:width-2
			# 1. rotwerte bestimmen
			# 1.1 bilineare interpolation
			red = red_bilin_interpol(bayer_filter, row, column)
			# 1.2 Laplace-Anteil addieren
			red += 1.5*(4*conv(bayer_filter[row, column].b) - conv(bayer_filter[row-2, column].b) - conv(bayer_filter[row, column-2].b) - conv(bayer_filter[row+2, column].b) - conv(bayer_filter[row, column+2].b)) / 8
			# 2 grünwerte bestimmen
			# 2.1 bilineare interpolation
			green = green_bilin_interpol(bayer_filter, row, column)
			# 2.2 Laplace-Anteil addieren
			green += (4*conv(bayer_filter[row, column].b) - conv(bayer_filter[row-2, column].b) - conv(bayer_filter[row, column-2].b) - conv(bayer_filter[row+2, column].b) - conv(bayer_filter[row, column+2].b)) / 8
			
			green = clamp(green, 0.0, 1.0)
			red = clamp(red, 0.0, 1.0)
			hqlin[row, column] = RGB(red, green, bayer_filter[row, column].b)
		end
		# grünes hotpixel
		for column in 4:2:width-2
			# 1. rotwert bestimmen
			# 1.1 bilineare interpolation
			red = red_bilin_interpol_vertical(bayer_filter, row, column)
			# 1.2 Laplace-Anteil addieren
			red += (5*conv(bayer_filter[row, column].g) - conv(bayer_filter[row-2, column].g) - conv(bayer_filter[row+2, column].g) - conv(bayer_filter[row-1, column-1].g) - conv(bayer_filter[row+1, column+1].g) - conv(bayer_filter[row+1, column-1].g) - conv(bayer_filter[row-1, column+1].g) + 0.5 * conv(bayer_filter[row, column-2].g) + conv(bayer_filter[row-2, column+2].g)) / 8
			# 1. blauwert bestimmen
			# 1.1 bilineare interpolation
			blue = blue_bilin_interpol_horizontal(bayer_filter, row, column)
			# 1.2 Laplace-Anteil addieren
			blue += (5*conv(bayer_filter[row, column].g) - conv(bayer_filter[row, column-2].g) - conv(bayer_filter[row, column+2].g) - conv(bayer_filter[row-1, column-1].g) - conv(bayer_filter[row+1, column+1].g) - conv(bayer_filter[row+1, column-1].g) - conv(bayer_filter[row-1, column+1].g) + 0.5 * conv(bayer_filter[row-2, column].g) + conv(bayer_filter[row+2, column].g)) / 8
			# werte zwischen 0 und 1 beschränken
			red = clamp(red, 0.0, 1.0)
			blue = clamp(blue, 0.0, 1.0)
			hqlin[row, column] = RGB(red, bayer_filter[row, column].g, blue)
		end
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
	(height, width) = size(bayer_filter)
	# ungerade Bildzeilen, in denen nur grüne und rote hotpixel sind
	for row in 3:2:height-2
		# rotes hotpixel
		for column in 4:2:width-2
			# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
			# 1.1 horizontaler gradient
			g_horizontal = abs(conv(bayer_filter[row, column-1].g) - conv(bayer_filter[row, column+1].g)) + abs(- conv(bayer_filter[row, column-2].r) + 2*conv(bayer_filter[row, column].r - conv(bayer_filter[row, column+2].r)))
			# 1.2 vertikaler gradient
			g_vertical = abs(conv(bayer_filter[row-1, column].g) - conv(bayer_filter[row+1, column].g)) + abs(- conv(bayer_filter[row-2, column].r) + 2*conv(bayer_filter[row, column].r - conv(bayer_filter[row+2, column].r)))
			
			# horizontaler gradient größer => vertikale kante => vertikale grünwerte für berechnung sinnvoller, da hier keine großen farbänderungen sind
			if g_vertical > g_horizontal
				# horizontale bilineare interpolation
				green = 0.5 * (conv(bayer_filter[row, column-1].g) + conv(bayer_filter[row, column+1].g))
				# horizontalen Laplace Anteil addieren
				green += 0.25 * (- conv(bayer_filter[row, column-2].r) + 2*conv(bayer_filter[row, column].r - conv(bayer_filter[row, column+2].r)))
			else
				# vertikale bilineare interpolation
				green = 0.5 * (conv(bayer_filter[row-1, column].g) + conv(bayer_filter[row+1, column].g)) 
				# vertikalen Laplace-Anteil addieren
				green += 0.25 * (- conv(bayer_filter[row-2, column].r) + 2*conv(bayer_filter[row, column].r - conv(bayer_filter[row+2, column].r)))
			end
			
			# grünwert zum rekonstruieren des grünkanals setzen
			green = clamp(green, 0.0, 1.0)
			acpi_green_channel[row, column] = RGB(bayer_filter[row, column].r, green, 0)
			
		end
	end
	
	# geraden Bildzeilen
	for row in 4:2:height-2
		# blaues hotpixel
		for column in 3:2:width-2
			# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
			# 1.1 horizontaler gradient
			g_horizontal = abs(conv(bayer_filter[row, column-1].g) - conv(bayer_filter[row, column+1].g)) + abs(- conv(bayer_filter[row, column-2].b) + 2*conv(bayer_filter[row, column].b - conv(bayer_filter[row, column+2].b)))
			# 1.2 vertikaler gradient
			g_vertical = abs(conv(bayer_filter[row-1, column].g) - conv(bayer_filter[row+1, column].g)) + abs(- conv(bayer_filter[row-2, column].b) + 2*conv(bayer_filter[row, column].b - conv(bayer_filter[row+2, column].b)))
			
			# 2. grünwerte bestimmen
			# horizontaler gradient größer => vertikale kante => vertikale grünwerte für berechnung sinnvoller, da hier keine großen farbänderungen sind
			if g_vertical > g_horizontal
				# horizontale bilineare interpolation
				green = 0.5 * (conv(bayer_filter[row, column-1].g) + conv(bayer_filter[row, column+1].g))
				# horizontalen Laplace Anteil addieren
				green += 0.25 * (- conv(bayer_filter[row, column-2].b) + 2*conv(bayer_filter[row, column].b - conv(bayer_filter[row, column+2].b)))
			else
				# vertikale bilineare interpolation
				green = 0.5 * (conv(bayer_filter[row-1, column].g) + conv(bayer_filter[row+1, column].g)) 
				# vertikalen Laplace-Anteil addieren
				green += 0.25 * (- conv(bayer_filter[row-2, column].b) + 2*conv(bayer_filter[row, column].b - conv(bayer_filter[row+2, column].b)))
			end
			# grünwert zum rekonstruieren des grünkanals setzen
			green = clamp(green, 0.0, 1.0)
			acpi_green_channel[row, column] = RGB(0, green, bayer_filter[row, column].b)
		end
	end
	
	#return acpi
	return acpi_green_channel
end

# ╔═╡ c00ec842-85a5-4554-94ce-628f28d34b09
begin
	acpi_green_luigi = acpi_green_channel(bayer_luigi)
	[bayer_luigi acpi_green_luigi]
end

# ╔═╡ 211756ce-1b62-491b-9914-a82cfdb663fa
function acpi_red_green(acpi_green_channel)
	acpi = copy(acpi_green_channel)
	(height, width) = size(acpi_green_channel)
	# Bildzeilen, in denen nur grüne und rote hotpixel sind
	for row in 3:2:height-2
		# grünes hotpixel
		for column in 3:2:width-2
			red = 0.5*(conv(acpi_green_channel[row, column-1].r) + conv(acpi_green_channel[row, column+1].r)) + 0.5 * (-conv(acpi_green_channel[row, column-1].g) + 2*conv(acpi_green_channel[row, column].g) - conv(acpi_green_channel[row, column+1].g))
			blue = 0.5*(conv(acpi_green_channel[row-1, column].b) + conv(acpi_green_channel[row+1, column].b)) + 0.5 * (-conv(acpi_green_channel[row-1, column].g) + 2*conv(acpi_green_channel[row, column].g) - conv(acpi_green_channel[row+1, column].g))
			
			# nur noch werte zwischen 0 und 1
			red = clamp(red, 0.0, 1.0)
			blue = clamp(blue, 0.0, 1.0)
			acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, blue)
		end
		# rotes hotpixel
		for column in 4:2:width-2
			# rekonstruieren des blaukanals
			# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
			# 1.1 diagonal negativer gradient (links unten nach rechts oben)
			g_neg = abs(conv(acpi_green_channel[row-1, column-1].b) - conv(acpi_green_channel[row+1, column+1].b)) + abs(- conv(acpi_green_channel[row-1, column-1].g) + 2*conv(acpi_green_channel[row, column].g - conv(acpi_green_channel[row+1, column+1].g)))
			# 1.2 diagonal positiver gradient (links oben nach rechts unten)
			g_pos = abs(conv(acpi_green_channel[row-1, column+1].b) - conv(acpi_green_channel[row+1, column-1].b)) + abs(- conv(acpi_green_channel[row-1, column+1].g) + 2*conv(acpi_green_channel[row, column].g - conv(acpi_green_channel[row+1, column-1].g)))
			
			# diagonal negativer gradient größer => diagonal positive grünwerte für berechnung sinnvoller
			if g_neg > g_pos # TODO: prüfen ob buch hier falsch liegt
				blue = 0.5 * (conv(acpi_green_channel[row-1, column-1].b) + conv(acpi_green_channel[row+1, column+1].b)) 
				blue += 0.25 * (- conv(acpi_green_channel[row-1, column-1].g) + 2*conv(acpi_green_channel[row, column].g - conv(acpi_green_channel[row+1, column+1].g)))
			else
				blue = 0.5 * (conv(acpi_green_channel[row-1, column+1].b) - conv(acpi_green_channel[row+1, column-1].b)) 
				blue += 0.25*(- conv(acpi_green_channel[row-1, column+1].g) + 2*conv(acpi_green_channel[row, column].g - conv(acpi_green_channel[row+1, column-1].g)))
			end

			# nur noch werte zwischen 0 und 1 
			blue = clamp(blue, 0.0, 1.0)
			acpi[row, column] = RGB(acpi_green_channel[row, column].r, acpi_green_channel[row, column].g, blue)

		end
	end
	
	# geraden Bildzeilen
	for row in 4:2:height-2
		# blaues hotpixel
		for column in 3:2:width-2
			# rekonstruieren des blaukanals
			# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
			# 1.1 diagonal negativer gradient (links unten nach rechts oben)
			g_neg = abs(conv(acpi_green_channel[row-1, column-1].r) - conv(acpi_green_channel[row+1, column+1].r)) + abs(- conv(acpi_green_channel[row-1, column-1].g) + 2*conv(acpi_green_channel[row, column].g - conv(acpi_green_channel[row+1, column+1].g)))
			# 1.2 diagonal positiver gradient (links oben nach rechts unten)
			g_pos = abs(conv(acpi_green_channel[row-1, column+1].r) - conv(acpi_green_channel[row+1, column-1].r)) + abs(- conv(acpi_green_channel[row-1, column+1].g) + 2*conv(acpi_green_channel[row, column].g - conv(acpi_green_channel[row+1, column-1].g)))
			
			# diagonal negativer gradient größer => diagonal positive grünwerte für berechnung sinnvoller
			if g_neg > g_pos # TODO: prüfen ob buch hier falsch liegt
				red = 0.5 * (conv(acpi_green_channel[row-1, column-1].r) + conv(acpi_green_channel[row+1, column+1].r)) 
				red += 0.25 * (- conv(acpi_green_channel[row-1, column-1].g) + 2*conv(acpi_green_channel[row, column].g - conv(acpi_green_channel[row+1, column+1].g)))
			else
				red = 0.5 * (conv(acpi_green_channel[row-1, column+1].r) - conv(acpi_green_channel[row+1, column-1].r)) 
				red += 0.25*(- conv(acpi_green_channel[row-1, column+1].g) + 2*conv(acpi_green_channel[row, column].g - conv(acpi_green_channel[row+1, column-1].g)))
			end

			# nur noch werte zwischen 0 und 1 
			red = clamp(red, 0.0, 1.0)
			acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, acpi_green_channel[row, column].b)
		end
		
		# grünes hotpixel
		for column in 4:2:width-2
			red = 0.5*(conv(acpi_green_channel[row-1, column].r) + conv(acpi_green_channel[row+1, column].r)) + 0.5 * (-conv(acpi_green_channel[row-1, column].g) + 2*conv(acpi_green_channel[row, column].g) - conv(acpi_green_channel[row+1, column].g))
			blue = 0.5*(conv(acpi_green_channel[row, column-1].b) + conv(acpi_green_channel[row, column+1].b)) + 0.5 * (-conv(acpi_green_channel[row, column-1].g) + 2*conv(acpi_green_channel[row, column].g) - conv(acpi_green_channel[row, column+1].g))
			
			# nur noch werte zwischen 0 und 1
			red = clamp(red, 0.0, 1.0)
			blue = clamp(blue, 0.0, 1.0)
			acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, blue)
		end
	end
	return acpi
end

# ╔═╡ bc8381e8-94ea-48a9-8897-61eb5826fae9
function acpi(bayer_filter)
	green_channel = acpi_green_channel(bayer_filter)
	return acpi_red_green(green_channel)
end

# ╔═╡ 6b76b17f-0328-4b35-90ba-b149b61cb63c
begin
	acpi_luigi = acpi(bayer_luigi)
	[bayer_luigi acpi_green_luigi acpi_luigi]
end

# ╔═╡ Cell order:
# ╠═3d6aecaa-a47e-4197-9f87-d34533f488ca
# ╠═5f647aac-e087-482a-af80-733fb387b73d
# ╠═bfa6f004-e3ab-4363-ab76-b14de80b272a
# ╠═ef83b17c-b66c-4734-aebe-6a6d9390b914
# ╠═39502556-161a-4efc-864b-fcf1755db8a4
# ╠═c9f06538-02ec-4dd5-a915-0140741b041f
# ╠═92c26370-a774-11eb-163a-3b4671b8c14b
# ╠═a136aaaf-d467-40fa-8fff-ad9817148e6c
# ╠═5be0f1f9-e4f5-4c17-81c4-258cf400ff87
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