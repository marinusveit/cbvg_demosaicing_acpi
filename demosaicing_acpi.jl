### A Pluto.jl notebook ###
# v0.14.4

using Markdown
using InteractiveUtils

# ╔═╡ 3d6aecaa-a47e-4197-9f87-d34533f488ca
# imports
begin
	import Pkg
	using Pkg
	Pkg.add(["PlutoUI", "Images", "TestImages", "ImageTransformations"])
	using ImageTransformations
	using TestImages
	using Images
	using PlutoUI
end


# ╔═╡ 50b5fd6d-f293-4824-a5f4-ee9def287be3
md"# Präsentation zum Thema Demosaicing


## Am Beispiel des Algorithmus ACPI ”Adaptive Color Plane Interpolation“ von Hamilton & Adams


##### von Felix Schnitzenbaumer, Marinus Veit, Simon Schröppel und Thorsten Schartel



Präsentation als [Pluto Notebook](https://github.com/marinusveit/cbvg_demosaicing_acpi/)"


# ╔═╡ 8e4b86a1-8bdc-4191-ad33-9a33d7720bd6
md"# Ablauf:


- Funktionsweise und Ziel des Algorithmus
- Ablauf des Algorithmus
- Praktische Beispiele und Vergleich mit anderen Algorithmen
- Zusammenfassung
"


# ╔═╡ b25ffb85-4841-45d9-abc7-6a4767a34eb0
md"# Funktionsweise und Ziel des Algorithmus:

- Mittelungen und Gradienten möglichst entlang von Kanten zu berechnen
- Bessere Vermeidung von Zipper – Effekten"


# ╔═╡ f99556f6-4096-4690-bd94-30525163b8be
md"
## Beispiel Original Bild vs. Bilineare Interpolation
![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/exampleStart.png)"



# ╔═╡ 4bfe8fea-c5c2-4e7b-ac79-f42cf6c38a2a
md"# Ablauf des Algorithmus:

- Erster Schritt: Rekonstruktion aller Grünwerte der roten- und blauen Hotpixel

 	![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/gradient_pixel_hv.png)

- Berechnung aller Grünwert-Gradienten der roten und blauen Pixel in horizontaler und vertikaler Richtung nach folgender Formel:

 ![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/gradient_hv.png)


- Je nachdem welcher Gradient der größere ist, wird eine der beiden folgenden Formeln zur Rekonstruktion des Grünkanals des betrachteten Pixels verwendet.

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/formel_gradient_hv.png)

- Der linke Teil des Terms entspricht dabei der bilinearen Interpolation der zweite der einem 1-dimensionalen Laplace-Filter.


- **Wichtig** wenn wir den höheren Gradienten auf der horizontalen berechnen verwenden wir für den Grünkanal die vertikale Achse und umgekehrt. Dies vermeidet das bereits genannte Zipper-Problem und erhält die Kanten des Originalbildes. 


- Somit haben wir jetzt für alle roten und blauen Hotpixel Grünwerte berechnet.


- Im folgenden Schritt werden die noch fehlenden Farbwerte der einzelnen Pixel anhand der berechnete Grünwerte berechnet. D.h. uns fehlen noch folgende Werte:

	-	rote Pixel -> Blauwert
	-	blaue Pixel -> Rotwert
	-	grüne Pixel -> Rot- und Blauwert

- Für die Berechnung der roten Pixel wird mithilfe der im vorherigen Schritt erhaltenen Grünwerte der diagonale Gradient nach folgender Formel berechnet. Die blauen Hotpixel werden analog rekonstruiert.


![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/gradient_pixel_d.png)

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/formel_gradient_d.png)

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/formel_gradient_d2.png)



- Für die Berechnung der fehlenden Farbwerte der grünen Pixel wird kein Gradient verwendet, da an diesen Stellen die Interpolation nur in eine Richtung möglich ist. 
![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/image_diagonal_pixel.png)

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/formel_gradient_green.png)

- Für jeden Pixel sind nun RGB Werte vorhanden



- Dieser Algorithmus bietet noch Verbesserunspotenzial



- Um die Farbwerte grüner Pixel bestimmen zu können müssen in diesem Fall erst alle Rotwerte Blauer Pixel und alle Blauwerte roter Pixel berechnet werden.

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/formel_rb_gradient_enhanced.png)

"



# ╔═╡ 07d8d0bb-1b5e-41fa-9315-dc8a408dca57
md"# Praktische Beispiele und Vergleich mit anderen Algorithmen"

# ╔═╡ bfa6f004-e3ab-4363-ab76-b14de80b272a


# ╔═╡ 8e3044b1-3841-4e67-8874-860a6bff1e73
md"## Imports"

# ╔═╡ 08647a94-2dcb-4087-a8ed-07813b24061d
md"## Funktionsdefinitonen"

# ╔═╡ b3aa857a-2a20-4a9a-b0c4-a4085b21eafd
function black_white_img(size)
	bwimg = rand(RGB, size, size)
	for row=1:1:size
		for column=1:1:size
			if row<=size/2 && column<=size/2 || row>size/2 && column>size/2
				bwimg[row, column]=RGB(1.0, 1.0, 1.0)
			else
				bwimg[row, column]=RGB(0.0, 0.0, 0.0)
			end
		end
	end
	return bwimg
end

# ╔═╡ 8d35277d-f963-48ed-b472-ca44ccb972be
decimate(image, ratio=5) = image[1:ratio:end, 1:ratio:end]

# ╔═╡ 5f647aac-e087-482a-af80-733fb387b73d
begin
	#								toptop
	#    			top_left 	 	top  			top_right
	# 	 left left 	left 		 	referenz Pixel  right 			rightright
	# 	 			bottom_left 	bottom 			bottom_right
	#								bottombottom
	#
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

	# funktion die den Kopf von Luigi extrahiert
	function head(image, resize)
		(height, width) = size(image)
		head = image[1:trunc(Int, height ÷ 2), trunc(Int, width ÷ 7):trunc(Int, width-6)]
		return imresize(head, ratio=resize)
		#return imresize(head, size(head).*resize)
	end
	

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
	#Der Bildrand wird nicht bearbeitet. An den Bildrändern könnte man Methoden wie das Zyklische Fortsetzen oder das Randpixel nach außen ausbreiten verwenden.
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

# ╔═╡ 955c3038-6203-43c3-b453-0e483725ae9b
function mean_square_error(original, reconstructed)
    if size(original) != size(reconstructed)
        return -1
    end
    (height, width) = size(original)
    total_sq_err = 0.0
    
    for row in 1:height
        for column in 1:width
            total_sq_err += (convert(Float32, original[row, column].r) - convert(Float32, reconstructed[row, column].r))^2
            total_sq_err += (convert(Float32, original[row, column].g) - convert(Float32, reconstructed[row, column].g))^2
            total_sq_err += (convert(Float32, original[row, column].b) - convert(Float32, reconstructed[row, column].b))^2
        end
    end
    
    return total_sq_err/(height * width * 3)
end

# ╔═╡ 98ed88b4-6359-48e4-8163-5904dea355a7
function image_section(image)
	return image[30:115,30:115]
end

# ╔═╡ e1afac97-a82e-4f52-89b5-7d3359c870f5
md"## Beispielbild"

# ╔═╡ 8b31c48b-c90e-473c-b2f8-fe514f761406
md"Es wird ein Beispielbild geladen, mit dem die verschiedenen Demosaicing Algorithmen getestet und verglichen werden sollen.

Dazu wird zunächst ein Bild in das Notebook geladen. Anschließend wird die Bildgröße reduziert, um die Unterschiede in den verschiedenen Demosaicing Algorithmen besser erkennbar zu machen."

# ╔═╡ 92c26370-a774-11eb-163a-3b4671b8c14b
begin
	#url="http://sipi.usc.edu/database/preview/misc/4.1.05.png"
	#download(url, "house.png")
	original_image = load("house.png")
	original_image = decimate(original_image, 2) # nur jedes 2. Pixel des Originalbildes
end

# ╔═╡ bf683c6e-bf61-47c3-9556-2cc9fec7f3e0
image_section(original_image)

# ╔═╡ c7aa1107-4e59-47da-af70-ae7608bc6065
md"## Bayer Farbfilter
- Photozellen einer Kamera können nur Helligkeitswerte erfassen
- vor jeder Zelle kleiner physikalischer Farbfilter in einen der drei Grundfarben
- Menschliches Auge erkennt Grün am besten
→ 50 % Grün, der Rest ist Blau und Rot

Der Bayer Farbfilter eines Bildes ist der Input für die Demosaicing Algorithmen.
"

# ╔═╡ e5530339-75e8-4441-9e7a-0f9356c217da
begin
	bayer_image = bayer_colorfilter(original_image)
end

# ╔═╡ 5d426f07-37d7-4c56-95cf-50d3fa6d25ac
md"### Bayer-Matrix
Hier ein kleiner Ausschnitt des Bayerfilters unseres Testbildes."

# ╔═╡ 8c1b7413-9b9e-44d0-9701-ade1fd3de536
begin
	bayer_image[10:20,10:20]
end

# ╔═╡ 1768def4-ce6b-4e77-835c-1049cdda2cd7
md"Vergleich des Originalbildes mit dem Bayer Frabfilter"

# ╔═╡ 1be3ace0-de06-4bd1-9d31-baaa9b154b18
begin
	imresize([image_section(original_image) image_section(bayer_image)], ratio=5)
end

# ╔═╡ e0532011-821c-4991-b982-db114cde65cf
md"Ziel des Demosaicing ist die bestmögliche Rekonstruktion der Farbwerte aus dem Bayer Farbfilter."

# ╔═╡ c1e450f0-862a-4ec9-aae0-0a64fd660d19
md"## Bilineare Interpolation
Die bilineare Interpolation ist ein sehr einfacher Demosaicing Algorithmus. Folgende Abbildung zeigt das Ergebnis, wenn man die bilineare Interpolation auf den Bayerfilter anwendet"

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

# ╔═╡ 1746ff45-7bae-4033-bec9-477ecfb47bd5
begin
	image_bilin = bilineare_interpolation(bayer_image)
	imresize(image_bilin, ratio=3)
end

# ╔═╡ aafc01fd-ca3d-4f73-875a-027f68996789
md"## High Quality Linear Demosacing (HQLIN)
Idee: Tiefpass-filternde Wirkung der bilinearen Inerpolation durch Addition des Laplace Anteils reduzieren"

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
begin
	image_hqlin = hqlin(bayer_image)
	imresize(image_hqlin, ratio=3)
end

# ╔═╡ 58e6f0ac-2e0a-4c3c-ad10-5bd6697cbc59
md"## Adaptive Color Plane Interpolation (ACPI)
ACPI verbessert das Demosaicing Ergebniss weiter, indem Mittelungen nur noch entlang von Kanten und nicht mehr senkrecht dazu erfolgen

`acpi_reconstruct_green_channel(bayer_filter)`:
- Berechnung des Gradienten in horizontaler und vertikaler Richtung
- Rekonstruktion des Grünkanals"

# ╔═╡ 48e4ae5d-5423-442c-9b4e-712f42b84bc2
function acpi_reconstruct_green_channel(bayer_filter)
	acpi_green_channel = copy(bayer_filter)

	# rotes hotpixel
	for (row, column) in redhotpixels(bayer_filter)
		# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
		# 1.1 horizontaler gradient
		g_horizontal = abs(sum_green_channel(bayer_filter, (row, column), (left, 1), (right, -1))) + abs(sum_red_channel(bayer_filter, (row, column), (left_left, -1), (current, 2), (right_right, -1)))
		# 1.2 vertikaler gradient
		g_vertical = abs(sum_green_channel(bayer_filter, (row, column), (top, 1), (bottom, -1))) + abs(sum_red_channel(bayer_filter, (row, column), (top_top, -1), (current, 2), (bottom_bottom, -1)))
		
# horizontaler gradient größer => vertikale kante => vertikale grünwerte für Berechnung sinnvoller, da hier keine großen Farbänderungen auftreten
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
		
		# grünwert zum Rekonstruieren des grünkanals setzen
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
			green = 0.5 * sum_green_channel(bayer_filter, (row, column), left, right)
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
	acpi_green_image = acpi_reconstruct_green_channel(bayer_image)
	imresize([bayer_image acpi_green_image], ratio=3)
end

# ╔═╡ f1959a0f-7dbc-470d-9d23-6a6883b4c335
md"`acpi_reconstruct_red_blue_channel(acpi_green_channel)`:
- Gradienten in diagonaler Richtung mit Hilfe des rekonstruierten Grünkanals bestimmen
- Blau- und Rotkanal rekonstruieren"

# ╔═╡ 211756ce-1b62-491b-9914-a82cfdb663fa
function acpi_reconstruct_red_blue_channel(acpi_green_channel)
	acpi = copy(acpi_green_channel)
	(height, width) = size(acpi_green_channel)

	# ungerade Bildzeilen
	# grünes hotpixel
	for (row, column) in green_red_hotpixels(acpi_green_channel)
		red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), left, right) 
		red += 0.5 * sum_green_channel(acpi_green_channel, (row, column), (left, -1), (current, 2), (right, -1))
		
		blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), bottom, top)
		blue += 0.5 * sum_green_channel(acpi_green_channel, (row, column), (bottom, -1), (current, 2), (top, -1))

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
		g_neg = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_left, 1), (bottom_right, -1))) 
		g_neg += abs(sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1)))
		# 1.2 diagonal positiver gradient (rechts oben nach links unten)
		g_pos = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_right, 1), (bottom_left, -1))) 
		g_pos += abs(sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1)))
		
		# diagonal negativer gradient kleiner => diagonal negative grünwerte für Berechnung sinnvoller
		if g_neg < g_pos
			blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), top_left, bottom_right)
			blue += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1))
		else # diagonal negativer gradient größer => diagonal positive grünwerte für Berechnung sinnvoller
			blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), top_right, bottom_left)
			blue += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1))
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
		g_neg = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_left, 1), (bottom_right, -1)))
		g_neg += abs(sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1)))
		# 1.2 diagonal positiver gradient (links oben nach rechts unten)
		g_pos = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_right, 1), (bottom_left, -1)))
		g_pos += abs(sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1)))
		
		# diagonal negativer gradient größer => diagonal positive grünwerte für berechnung sinnvoller
		if g_neg < g_pos # TODO: prüfen ob buch hier falsch liegt
			red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), top_left, bottom_right)
			red += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1))
		else
			red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), top_right, bottom_left)
			red += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1))
		end
		# nur noch werte zwischen 0 und 1 
		red = clamp(red, 0.0, 1.0)
		acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, acpi_green_channel[row, column].b)
	end
		
	# grünes hotpixel
	for (row, column) in green_blue_hotpixels(acpi_green_channel)
		red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), bottom, top)
		red += 0.5 * sum_green_channel(acpi_green_channel, (row, column), (bottom, -1), (current, 2), (top, -1))
		blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), left, right)
		blue += 0.5 * sum_green_channel(acpi_green_channel, (row, column), (left, -1), (current, 2), (right, -1))
		
		# nur noch werte zwischen 0 und 1
		red = clamp(red, 0.0, 1.0)
		blue = clamp(blue, 0.0, 1.0)
		acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, blue)
	end
	return acpi
end

# ╔═╡ 490a92e7-d177-427a-9fec-742bc0fae5e5
md"**`acpi(bayer_filter)`:**
1. Grünkanal rekonstruieren: `green_channel = acpi_reconstruct_green_channel(bayer_filter)`
2. Blau und Rotkanal rekonstruieren: `acpi_reconstruct_red_blue_channel(green_channel)`"

# ╔═╡ bc8381e8-94ea-48a9-8897-61eb5826fae9
function acpi(bayer_filter)
	green_channel = acpi_reconstruct_green_channel(bayer_filter)
	return acpi_reconstruct_red_blue_channel(green_channel)
end

# ╔═╡ d884903b-32cf-415c-8b52-5017090e3a19
md"## Vergleich der erzeugten Bilder"

# ╔═╡ 9b8c48ab-3b38-4eb6-80ed-df1dedbd2b4e
md"### Original Bild / Bayer Farbfilter / rekonstruierter Grünkanal / ACPI"

# ╔═╡ 6b76b17f-0328-4b35-90ba-b149b61cb63c
begin
	acpi_image = acpi(bayer_image)
	tmp = [image_section(original_image) image_section(bayer_image) image_section(acpi_green_image) image_section(acpi_image)]
	imresize(tmp, ratio=5)
end

# ╔═╡ 79361e3a-2560-4c5a-9b46-4f7bf806a4b3
md"### Original Bild / Bilineare Interpolation / HQLIN / ACPI"

# ╔═╡ 0df3e1b9-dab5-4087-b5ba-c89f67f67380
 imresize([image_section(original_image) image_section(image_bilin) image_section(image_hqlin) image_section(acpi_image)], ratio=5)

# ╔═╡ 2c514fdb-d728-41db-bfba-1ea757b41b4d
 imresize([original_image[50:100, 90:110] image_bilin[50:100, 90:110] image_hqlin[50:100, 90:110] acpi_image[50:100, 90:110]], ratio=5)

# ╔═╡ be312185-0455-4ad0-8972-ce251038d999
md"## Verbesserter ACPI Algorithmus"

# ╔═╡ b42bc451-71fd-48bf-b8c3-478b9de5d506
function acpi_reconstruct_red_blue_channel_improved(acpi_green_channel)
	acpi = copy(acpi_green_channel)
	(height, width) = size(acpi_green_channel)

	#1. Rekonstruieren der Rot- bzw. Blauwerte für blaue bzw. rote Hotpixel
	
	# rotes hotpixel
	for (row, column) in redhotpixels(acpi_green_channel)
		# rekonstruieren des Blaukanals
		# 1. Gradienten bestimmen
		# 1.1 diagonal negativer gradient (links oben nach rechts unten)
		g_neg = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_left, 1), (bottom_right, -1)))
		g_neg += abs(sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1)))
		# 1.2 diagonal positiver gradient (rechts oben nach links unten)
		g_pos = abs(sum_blue_channel(acpi_green_channel, (row, column), (top_right, 1), (bottom_left, -1)))
		g_pos += abs(sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1)))
		
		# diagonal positiver gradient größer => rekonstruktion in diagonal negative Richtung
		if g_neg <= g_pos
			blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), top_left, bottom_right)
			blue += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1))
		else
			blue = 0.5 * sum_blue_channel(acpi_green_channel, (row, column), top_right, bottom_left)
			blue += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1))
		end
			# nur noch werte zwischen 0 und 1 
		blue = clamp(blue, 0.0, 1.0)
		acpi[row, column] = RGB(acpi_green_channel[row, column].r, acpi_green_channel[row, column].g, blue)
	end
	
	# blaues hotpixel
	for (row, column) in bluehotpixels(acpi_green_channel)
		# rekonstruieren des blaukanals
		# 1. Gradienten bestimmen => sehen wo eventuell eine Kante ist
		# 1.1 diagonal negativer gradient (links oben nach rechts unten)
		g_neg = abs(sum_red_channel(acpi_green_channel, (row, column), (top_left, 1), (bottom_right, -1)))
		g_neg += abs(sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1)))
		# 1.2 diagonal positiver gradient (links oben nach rechts unten)
		g_pos = abs(sum_red_channel(acpi_green_channel, (row, column), (top_right, 1), (bottom_left, -1)))
		g_pos += abs(sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1)))
		
		# diagonal positiver gradient größer => rekonstruktion in diagonal negative Richtung
		if g_neg <= g_pos
			red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), top_left, bottom_right)
			red += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_left, -1), (current, 2), (bottom_right, -1))
		else
			red = 0.5 * sum_red_channel(acpi_green_channel, (row, column), top_right, bottom_left)
			red += 0.25 * sum_green_channel(acpi_green_channel, (row, column), (top_right, -1), (current, 2), (bottom_left, -1))
		end
		# nur noch werte zwischen 0 und 1 
		red = clamp(red, 0.0, 1.0)
		acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, acpi_green_channel[row, column].b)
	end
	# blaue und rote Hotpixel sind jetzt vollständig rekonstruiert
	
	# Rot-/Blauwerte für grüne Hotpixel berechenen.	
	
	# grünes hotpixel
	for (row, column) in [reshape(green_red_hotpixels(acpi_green_channel), :, 1) ; reshape(green_blue_hotpixels(acpi_green_channel), :, 1)]
		
		# Rot rekonstruieren:
		g_horizontal_red = abs(sum_red_channel(acpi, (row, column), (left, 1), (right, -1)))
		g_horizontal_red += abs(sum_green_channel(acpi, (row, column), (left, -1), (current, 2), (right, -1)))
		g_vertical_red = abs(sum_red_channel(acpi, (row, column), (top, 1), (bottom, -1)))
		g_vertical_red += abs(sum_green_channel(acpi, (row, column), (top, -1), (current, 2), (bottom, -1)))
		
		if g_horizontal_red > g_vertical_red
			red = 0.5 * sum_red_channel(acpi, (row, column), top, bottom)
			red += 0.5 * sum_green_channel(acpi, (row, column), (top, -1), (current, 2), (bottom, -1))
		else
			red = 0.5 * sum_red_channel(acpi, (row, column), left, right)
			red += 0.5 * sum_green_channel(acpi, (row, column), (left, -1), (current, 2), (right, -1))
		end
		
		# Blau rekonstruieren
		g_horizontal_blue = abs(sum_blue_channel(acpi, (row, column), (left, 1), (right, -1)))
		g_horizontal_blue += abs(sum_green_channel(acpi, (row, column), (left, -1), (current, 2), (right, -1)))
		g_vertical_blue = abs(sum_blue_channel(acpi, (row, column), (top, 1), (bottom, -1)))
		g_vertical_blue += abs(sum_green_channel(acpi, (row, column), (top, -1), (current, 2), (bottom, -1)))
		
		if g_horizontal_blue > g_vertical_blue
			blue = 0.5 * sum_blue_channel(acpi, (row, column), top, bottom)
			blue += 0.5 * sum_green_channel(acpi, (row, column), (top, -1), (current, 2), (bottom, -1))
		else
			blue = 0.5 * sum_blue_channel(acpi, (row, column), left, right)
			blue += 0.5 * sum_green_channel(acpi, (row, column), (left, -1), (current, 2), (right, -1))
		end
		
		# nur noch werte zwischen 0 und 1
		red = clamp(red, 0.0, 1.0)
		blue = clamp(blue, 0.0, 1.0)
		acpi[row, column] = RGB(red, acpi_green_channel[row, column].g, blue)
	end	
	return acpi
end

# ╔═╡ 4911dcb5-16e4-49ac-b0a8-1147f373eb03
function acpi_improved(bayer_filter)
	green_channel = acpi_reconstruct_green_channel(bayer_filter)
	return acpi_reconstruct_red_blue_channel_improved(green_channel)
end

# ╔═╡ f47cc464-3d1a-4f39-bcfc-5ede3415fdc3
md"### Vergleich Ergebnis ACPI / ACPI-Improved"

# ╔═╡ 8252df35-e34d-4b2a-b486-5da09ece671f
begin
	acpi_impr_image = acpi_improved(bayer_image)
	#acpi_comp = [acpi_image acpi_impr_image]
	acpi_comp = [image_section(acpi_image) image_section(acpi_impr_image)]
	imresize(acpi_comp, ratio=5)
end

# ╔═╡ 4a228070-b157-4fb5-83b1-b85b3c31f40a
#[bayer_image[63:77, 93:107] acpi_image[63:77, 93:107] acpi_impr_image[63:77, 93:107]]
md"
Detailausschnitt Dachrinne (BayerFilter, ACPI, ACPI Improved)
	
![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/acpi_improved_house_detail.png)
"

# ╔═╡ a4b9cbdf-58a7-4ce7-ad46-1a8d1ff27050
md"
### Vergleich: BayerFilter, ACPI und ACPI-Improved
Zipper-Effekte die durch diagonales Sampling entstehen, werden entlang der Kante geglättet
"

# ╔═╡ e8f81364-485c-4f61-be30-75f29548d198
md"
Beispiel: Schwarz-Weiss Kanten"

# ╔═╡ 306354e6-44a2-4772-971c-7eabefc14063
black_white_img(20)

# ╔═╡ e11352e5-3777-490a-a97b-94cd524f674b
md"
Zur Erinnerung:
Diagonale Interpolation bei roten und blauen Hotpixeln

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/gradient_pixel_d.png)

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/formel_gradient_d.png)

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/formel_gradient_d2.png)


![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/acpi_improved_black_white_edge.png)

Detailansicht:

![alternative text](https://raw.githubusercontent.com/marinusveit/cbvg_demosaicing_acpi/develop/bilder/detail_acpi_improved_black_white_edge.png)

Durch das diagonale Interpolieren entsteht an vertikalen/horizontalen Kanten ein Zipper-Effekt

Werden Rot- und Blauwerte grüner Hotpixel nun im verbesserten ACPI Algorithmus entlang von Kanten rekonstruiert, werden diese Zipper geglättet
(entscheidender Teil: B = 0.5 * (B_left + B_right))
"

# ╔═╡ 9c144a8a-0870-46e9-9dfa-d36c24f78bc1
begin
	bw_size=40
	bw = black_white_img(bw_size)
	bw_bayer = bayer_colorfilter(bw)
	acpi_bw = acpi(bw_bayer)
	acpi_impr_bw = acpi_improved(bw_bayer)
	#Image comparisons used for Screenshots above
	#don't show boarders which are not reconstructed
	[bw_bayer[4:bw_size-4, 4:bw_size-4] acpi_bw[4:bw_size-4, 4:bw_size-4] acpi_impr_bw[4:bw_size-4, 4:bw_size-4]]
	[bw_bayer[18:23, 14:18] acpi_bw[18:23, 14:18] acpi_impr_bw[18:23, 14:18]]
	md"
	(Code: Vergleich Schwarz-Weiss Kanten)
	"
end

# ╔═╡ 6fe25fc4-dc21-49bc-bff6-0e65d714761e
begin
	bilin_mse = mean_square_error(original_image, image_bilin)
	hqlin_mse = mean_square_error(original_image, image_hqlin)
	acpi_mse = mean_square_error(original_image, acpi_image)
	acpi_impr_mse = mean_square_error(original_image, acpi_impr_image)
md"
### Vergleich: Abweichung vom Originalbild für verschiedene Demosaicing Verfahren

am Beispiel des roten Haus:
	
| Demosaicing Algorithmus        | Mean Squared Error| Mean Error             |
| ------------------------------ |:----------------- |:---------------------- |
| Bilineare Interpolation        | $(bilin_mse)      | $(sqrt(bilin_mse))     |
| HQLin                          | $(hqlin_mse)      | $(sqrt(hqlin_mse))     |
| ACPI                           | $(acpi_mse)       | $(sqrt(acpi_mse))      |
| ACPI Improved                  | $(acpi_impr_mse)  | $(sqrt(acpi_impr_mse)) |
	"
end

# ╔═╡ 75b637cb-30ec-40a6-9234-39e812ed96b4
md"# Zusammenfassung

Pro:
- Reduzierter Zipper-Effekt durch Interpolation entlang von Kanten
- Dadurch schärferes Bild

Contra:
- Der Rechenaufwand wird verdoppelt, da für jeden Farbwert erst die zwei Gradienten berechnet werden müssen
- Reihenfolge der Farbwertberechnung entscheidend (Grün -> Rot / Blau)
- dadurch schlechter parallelisierbar

"

# ╔═╡ c4862dba-90dc-458f-b70a-073eae112f28
md"
# Quellen:
A. Nischwitz, M. Fischer, G. Socher, P. Haberäcker
Bildverarbeitung, Band 2 des Standardwerks Computergrafik und Bildverarbeitung
ISBN 978-3-658-28704-7
Springer Vieweg, Wiesbaden, 2020

Bilder: [USC Universiy of Southern California, Signal and Image Processing Institute](http://sipi.usc.edu/database/database.php?volume=misc&image=5#top)
"

# ╔═╡ Cell order:
# ╟─50b5fd6d-f293-4824-a5f4-ee9def287be3
# ╟─8e4b86a1-8bdc-4191-ad33-9a33d7720bd6
# ╟─b25ffb85-4841-45d9-abc7-6a4767a34eb0
# ╟─f99556f6-4096-4690-bd94-30525163b8be
# ╟─4bfe8fea-c5c2-4e7b-ac79-f42cf6c38a2a
# ╟─07d8d0bb-1b5e-41fa-9315-dc8a408dca57
# ╟─bfa6f004-e3ab-4363-ab76-b14de80b272a
# ╟─8e3044b1-3841-4e67-8874-860a6bff1e73
# ╟─3d6aecaa-a47e-4197-9f87-d34533f488ca
# ╟─08647a94-2dcb-4087-a8ed-07813b24061d
# ╟─b3aa857a-2a20-4a9a-b0c4-a4085b21eafd
# ╟─8d35277d-f963-48ed-b472-ca44ccb972be
# ╟─5f647aac-e087-482a-af80-733fb387b73d
# ╟─ef83b17c-b66c-4734-aebe-6a6d9390b914
# ╟─429b0bc0-4e24-48b6-807d-08bb5f39aae2
# ╟─39502556-161a-4efc-864b-fcf1755db8a4
# ╟─955c3038-6203-43c3-b453-0e483725ae9b
# ╟─98ed88b4-6359-48e4-8163-5904dea355a7
# ╟─e1afac97-a82e-4f52-89b5-7d3359c870f5
# ╟─8b31c48b-c90e-473c-b2f8-fe514f761406
# ╟─92c26370-a774-11eb-163a-3b4671b8c14b
# ╟─bf683c6e-bf61-47c3-9556-2cc9fec7f3e0
# ╟─c7aa1107-4e59-47da-af70-ae7608bc6065
# ╟─e5530339-75e8-4441-9e7a-0f9356c217da
# ╟─5d426f07-37d7-4c56-95cf-50d3fa6d25ac
# ╟─8c1b7413-9b9e-44d0-9701-ade1fd3de536
# ╟─1768def4-ce6b-4e77-835c-1049cdda2cd7
# ╟─1be3ace0-de06-4bd1-9d31-baaa9b154b18
# ╟─e0532011-821c-4991-b982-db114cde65cf
# ╟─c1e450f0-862a-4ec9-aae0-0a64fd660d19
# ╟─c9f06538-02ec-4dd5-a915-0140741b041f
# ╟─1746ff45-7bae-4033-bec9-477ecfb47bd5
# ╟─aafc01fd-ca3d-4f73-875a-027f68996789
# ╟─826b8cc7-e2fb-4217-9737-0fa7119dca8d
# ╟─8db7f71e-0bcc-40c1-be67-7177b251ddae
# ╟─58e6f0ac-2e0a-4c3c-ad10-5bd6697cbc59
# ╠═48e4ae5d-5423-442c-9b4e-712f42b84bc2
# ╟─c00ec842-85a5-4554-94ce-628f28d34b09
# ╟─f1959a0f-7dbc-470d-9d23-6a6883b4c335
# ╠═211756ce-1b62-491b-9914-a82cfdb663fa
# ╟─490a92e7-d177-427a-9fec-742bc0fae5e5
# ╟─bc8381e8-94ea-48a9-8897-61eb5826fae9
# ╟─d884903b-32cf-415c-8b52-5017090e3a19
# ╟─9b8c48ab-3b38-4eb6-80ed-df1dedbd2b4e
# ╟─6b76b17f-0328-4b35-90ba-b149b61cb63c
# ╟─79361e3a-2560-4c5a-9b46-4f7bf806a4b3
# ╟─0df3e1b9-dab5-4087-b5ba-c89f67f67380
# ╟─2c514fdb-d728-41db-bfba-1ea757b41b4d
# ╟─be312185-0455-4ad0-8972-ce251038d999
# ╠═b42bc451-71fd-48bf-b8c3-478b9de5d506
# ╟─4911dcb5-16e4-49ac-b0a8-1147f373eb03
# ╟─f47cc464-3d1a-4f39-bcfc-5ede3415fdc3
# ╟─8252df35-e34d-4b2a-b486-5da09ece671f
# ╟─4a228070-b157-4fb5-83b1-b85b3c31f40a
# ╟─a4b9cbdf-58a7-4ce7-ad46-1a8d1ff27050
# ╟─e8f81364-485c-4f61-be30-75f29548d198
# ╟─306354e6-44a2-4772-971c-7eabefc14063
# ╟─e11352e5-3777-490a-a97b-94cd524f674b
# ╟─9c144a8a-0870-46e9-9dfa-d36c24f78bc1
# ╟─6fe25fc4-dc21-49bc-bff6-0e65d714761e
# ╟─75b637cb-30ec-40a6-9234-39e812ed96b4
# ╟─c4862dba-90dc-458f-b70a-073eae112f28
