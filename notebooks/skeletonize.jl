### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ e022fd52-dacb-11eb-1136-ada93cc10429
begin
	let
		using Pkg
		Pkg.activate(mktempdir())
		Pkg.Registry.update()
		Pkg.add(url="https://github.com/Dale-Black/ActiveContours.jl.git")
		Pkg.add("Plots")
		Pkg.add("Images")
		Pkg.add("ImageMorphology")
		Pkg.add("NIfTI")
	end
	
	using PlutoUI
	using ActiveContours
	using Plots
	using Images
	using ImageMorphology
	using NIfTI
end

# ╔═╡ 1aa9004a-7de8-4f91-87ba-b971920516e5
TableOfContents()

# ╔═╡ 1d486bc5-a2a0-4f87-b394-13869c97fe4a
md"""
## Create ellipsoid array
"""

# ╔═╡ 83c29cff-b06d-4d07-a9a5-9aa02a9f6cdd
begin
	image_shape = (50, 50, 10)
	ellipse = lazy_ellipsoid_level_set(image_shape)
	array = to_array(image_shape, ellipse)
end;

# ╔═╡ 0589a5ae-df11-4c57-ac7e-040a0b4b0e4f
md"""
## Skeletonize
"""

# ╔═╡ 2a02b838-3d3b-46d5-8f01-31d5b85796f3
function skeletonize3D(img)
	container = zeros(size(img))
	for z in 1:size(img)[3]
		container[:,:,z] = thinning(img[:,:,z])
	end
	return container
end

# ╔═╡ c063fc11-8e51-48a3-9717-41889ae86eae
centerline = skeletonize3D(array);

# ╔═╡ ad723094-4bba-4fdc-b16c-a695f5a224d4
md"""
## Visualize arrays
"""

# ╔═╡ c2fc1217-f2bb-49e1-929c-15701d44d7cc
@bind a PlutoUI.Slider(1:10, default=8, show_value=true)

# ╔═╡ e7f04569-3024-49cc-b9b0-e4a65c944c4a
heatmap(array[:,:,a])

# ╔═╡ ffa49ce7-1d14-4f10-9b32-a3166f0efb6b
heatmap(centerline[:,:,a])

# ╔═╡ 41c896f9-bb13-4f0a-bb8d-c1c6e08768c0
md"""
## Load NIfTI array
"""

# ╔═╡ 2556d699-b489-46d9-8e97-1edf1fe37454
image_path = "/Users/daleblack/Google Drive/Datasets/Task02_Heart/imagesTr/la_003.nii.gz";

# ╔═╡ 2bcb91d3-c880-4f0e-b862-327f58b66f47
label_path = "/Users/daleblack/Google Drive/Datasets/Task02_Heart/labelsTr/la_003.nii.gz";

# ╔═╡ d53e9e9e-e506-4ceb-9353-4435b80a7aab
begin
	img = niread(image_path)
	img_array = copy(img.raw)
	
	lbl = niread(label_path)
	lbl_array = copy(lbl.raw)
end;

# ╔═╡ 731dc332-5d96-4e57-874a-eb1acc87d956
unique(lbl_array)

# ╔═╡ c475b2f9-dc82-4294-ae8d-fe438e11966a
center = skeletonize3D(Bool.(lbl_array))

# ╔═╡ 78f8d449-2667-43c9-9aad-014f45a85900
@bind b PlutoUI.Slider(1:size(lbl_array)[3], default=100, show_value=true)

# ╔═╡ baa23bce-180b-4b13-9ee0-f8647f58861f
heatmap(img_array[:,:,b], c=:grays)

# ╔═╡ 8a5df198-5f48-4244-92a8-9b585ae2f4e2
heatmap(lbl_array[:,:,b])

# ╔═╡ 76e26f1c-0b62-4b69-afb7-e7eb95ba9027
heatmap(center[:,:,b])

# ╔═╡ b23e74be-fba5-4774-9db3-949d0a0a21dc
md"""
## Save as .mat file
"""

# ╔═╡ Cell order:
# ╠═e022fd52-dacb-11eb-1136-ada93cc10429
# ╠═1aa9004a-7de8-4f91-87ba-b971920516e5
# ╟─1d486bc5-a2a0-4f87-b394-13869c97fe4a
# ╠═83c29cff-b06d-4d07-a9a5-9aa02a9f6cdd
# ╟─0589a5ae-df11-4c57-ac7e-040a0b4b0e4f
# ╠═2a02b838-3d3b-46d5-8f01-31d5b85796f3
# ╠═c063fc11-8e51-48a3-9717-41889ae86eae
# ╟─ad723094-4bba-4fdc-b16c-a695f5a224d4
# ╠═c2fc1217-f2bb-49e1-929c-15701d44d7cc
# ╠═e7f04569-3024-49cc-b9b0-e4a65c944c4a
# ╠═ffa49ce7-1d14-4f10-9b32-a3166f0efb6b
# ╟─41c896f9-bb13-4f0a-bb8d-c1c6e08768c0
# ╠═2556d699-b489-46d9-8e97-1edf1fe37454
# ╠═2bcb91d3-c880-4f0e-b862-327f58b66f47
# ╠═d53e9e9e-e506-4ceb-9353-4435b80a7aab
# ╠═731dc332-5d96-4e57-874a-eb1acc87d956
# ╠═c475b2f9-dc82-4294-ae8d-fe438e11966a
# ╠═baa23bce-180b-4b13-9ee0-f8647f58861f
# ╠═78f8d449-2667-43c9-9aad-014f45a85900
# ╠═8a5df198-5f48-4244-92a8-9b585ae2f4e2
# ╠═76e26f1c-0b62-4b69-afb7-e7eb95ba9027
# ╟─b23e74be-fba5-4774-9db3-949d0a0a21dc
