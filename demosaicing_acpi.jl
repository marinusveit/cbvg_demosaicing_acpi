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
	using TestImages
	using Images
	using PlutoUI
end

# ╔═╡ 5f647aac-e087-482a-af80-733fb387b73d
begin
	function green_value(color)
		return RGB(0, color.g, 0)
	end
	function red_value(color)
		return RGB(color.r, 0, 0)
	end
	function blue_value(color)
		return RGB(0, 0, color.b)
	end
end

# ╔═╡ 20e3aaba-bf17-4865-bab2-dea1f7e0f8e9
function conv(n0fb)
	return convert(Float32, n0fb)
end

# ╔═╡ bfa6f004-e3ab-4363-ab76-b14de80b272a
html"""<style>
main {
    max-width: 1000px;
}
"""

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
		# in ungeraden Bildspalten die grünwerte abtasten
		for image_column in 1:2:width
			bayer_filter[image_row, image_column] = blue_value(image[image_row, image_column])
		end
		# in geraden Bildspalten die rotwerte abtasten
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
			blue = (conv(bayer_filter[image_row-1, image_column].b) + conv(bayer_filter[image_row+1, image_column].b)) / 2
			red = (conv(bayer_filter[image_row, image_column-1].r) + conv(bayer_filter[image_row, image_column+1].r)) / 2
			bilin_interpol[image_row, image_column] = RGB(red, bayer_filter[image_row, image_column].g, blue)			
		end
		# roter pixel
		for image_column in 2:2:width-1
			# todo ecken bekommen auslagern
			blue = (conv(bayer_filter[image_row-1, image_column-1].b) + conv(bayer_filter[image_row-1, image_column+1].b) + conv(bayer_filter[image_row+1, image_column+1].b) + conv(bayer_filter[image_row+1, image_column-1].b)) / 4
			green = (conv(bayer_filter[image_row, image_column-1].g) + conv(bayer_filter[image_row, image_column+1].g) + conv(bayer_filter[image_row-1, image_column].g) + conv(bayer_filter[image_row+1, image_column].g)) / 4
			bilin_interpol[image_row, image_column] = RGB(bayer_filter[image_row, image_column].r, green, blue)
		end
	end
	
	# geraden Bildzeilen
	for image_row in 2:2:height-1
		# blauer pixel
		for image_column in 3:2:width-1
			red = (conv(bayer_filter[image_row-1, image_column-1].r) + conv(bayer_filter[image_row-1, image_column+1].r) + conv(bayer_filter[image_row+1, image_column+1].r) + conv(bayer_filter[image_row+1, image_column-1].r)) / 4
			
			green = (conv(bayer_filter[image_row, image_column-1].g) + conv(bayer_filter[image_row, image_column+1].g) + conv(bayer_filter[image_row-1, image_column].g) + conv(bayer_filter[image_row+1, image_column].g)) / 4
			bilin_interpol[image_row, image_column] = RGB(red, green, bayer_filter[image_row, image_column].b)
		end
		# grüner pixel
		for image_column in 2:2:width-1
			blue = (conv(bayer_filter[image_row, image_column-1].b) + conv(bayer_filter[image_row, image_column+1].b)) / 2
			red = (conv(bayer_filter[image_row-1, image_column].r) + conv(bayer_filter[image_row+1, image_column].r)) / 2
			bilin_interpol[image_row, image_column] = RGB(red, bayer_filter[image_row, image_column].g, blue)
		end
	end
	return bilin_interpol
end

# ╔═╡ 92c26370-a774-11eb-163a-3b4671b8c14b
begin
	url = "https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/49c5b1cb-dc91-4d68-8aad-91b7c444aa77/dbpsnv9-68a6a080-4136-479d-bf58-ab38ebfad2e6.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcLzQ5YzViMWNiLWRjOTEtNGQ2OC04YWFkLTkxYjdjNDQ0YWE3N1wvZGJwc252OS02OGE2YTA4MC00MTM2LTQ3OWQtYmY1OC1hYjM4ZWJmYWQyZTYuanBnIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.CiJ9jFsCBqlWUjSjMX9WHJEK-D7vpHHEi82oaI-44LI"

	download(url, "testimage.jpg")
end

# ╔═╡ a136aaaf-d467-40fa-8fff-ad9817148e6c
begin
	luigi = load("testimage.jpg")
end

# ╔═╡ 5be0f1f9-e4f5-4c17-81c4-258cf400ff87
bayer_luigi = bayer_colorfilter(luigi)

# ╔═╡ 1be3ace0-de06-4bd1-9d31-baaa9b154b18
bayer_luigi[50:100, 1:100]

# ╔═╡ 8c1b7413-9b9e-44d0-9701-ade1fd3de536
bayer_luigi[1:10,1:10]

# ╔═╡ 1746ff45-7bae-4033-bec9-477ecfb47bd5
luigi_bilineare_interpolation = bilineare_interpolation(bayer_luigi)


# ╔═╡ f1e04739-fa0a-4a79-bc1e-a62923813b62
hcat(luigi, bayer_luigi,luigi_bilineare_interpolation)

# ╔═╡ Cell order:
# ╠═3d6aecaa-a47e-4197-9f87-d34533f488ca
# ╠═5f647aac-e087-482a-af80-733fb387b73d
# ╠═20e3aaba-bf17-4865-bab2-dea1f7e0f8e9
# ╠═bfa6f004-e3ab-4363-ab76-b14de80b272a
# ╠═39502556-161a-4efc-864b-fcf1755db8a4
# ╠═c9f06538-02ec-4dd5-a915-0140741b041f
# ╠═92c26370-a774-11eb-163a-3b4671b8c14b
# ╠═a136aaaf-d467-40fa-8fff-ad9817148e6c
# ╠═5be0f1f9-e4f5-4c17-81c4-258cf400ff87
# ╠═1be3ace0-de06-4bd1-9d31-baaa9b154b18
# ╠═8c1b7413-9b9e-44d0-9701-ade1fd3de536
# ╠═1746ff45-7bae-4033-bec9-477ecfb47bd5
# ╠═f1e04739-fa0a-4a79-bc1e-a62923813b62
