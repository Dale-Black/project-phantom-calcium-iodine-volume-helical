### A Pluto.jl notebook ###
# v0.15.1

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

# ╔═╡ 85e8a0e3-4de3-4933-9a52-35436bbde55f
begin
	let
		using Pkg
		Pkg.activate(mktempdir())
		Pkg.Registry.update()
		Pkg.add("BenchmarkTools")
		Pkg.add("CairoMakie")
		Pkg.add("Revise")
		Pkg.add(url="https://github.com/JuliaNeuroscience/NIfTI.jl")
		Pkg.add("DICOM")
		Pkg.add("Images")
		Pkg.add("ImageMorphology")
		Pkg.add("DataFrames")
		Pkg.add(url="https://github.com/Dale-Black/IntegratedHU.jl")
		Pkg.add(url="https://github.com/Dale-Black/DICOMUtils.jl")
		Pkg.add("PlutoUI")
	end
	
	using Revise
	using PlutoUI
	using Statistics
	using BenchmarkTools
	using CairoMakie
	using DICOM
	using NIfTI
	using Images
	using ImageMorphology
	using DataFrames
	using IntegratedHU
	using DICOMUtils
end

# ╔═╡ 401e5509-40bf-48f8-8593-fd4f538c6805
TableOfContents()

# ╔═╡ baa7cd06-10e6-4f9a-8ffd-1f458253d5fb
md"""
## Load data
Currently, this notebook only loads the 100 kV segmentation. This should be updated to load all 4 kV's (80, 100, 120, 135)
"""

# ╔═╡ 06db439a-134e-4484-8f10-9102cfef5352
md"""
### 80 kV
"""

# ╔═╡ 2fc032ad-b041-4fc4-8661-53b9fde5563d
image_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\49\80.0";

# ╔═╡ 639cd8f6-e16a-46dd-9430-8c38ce3648ae
label_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\HEL_SLICER_SEG_0\80\L_5.0.nii";

# ╔═╡ dc44351b-c4fb-44e3-918e-75a87dd3fb1a
begin
	lbl = niread(label_path)
	lbl_array = copy(lbl.raw)
end;

# ╔═╡ 6ebd6d62-c26b-4c72-ad90-f109f4da35f5
NIfTI.orientation(lbl)

# ╔═╡ 8b12e0d6-1285-4bca-bf79-0c629c1aec27
img = dcmdir_parse(image_path);

# ╔═╡ a2201222-dfb5-46d2-a40b-e36f390a2218
md"""
#### Reorient DICOM
"""

# ╔═╡ 1f4ab494-12e4-498b-b8fe-eabb68f9638d
begin
	aff = get_affine(img)
	io = io_orientation(aff)
	ornt2axcodes(io)
end

# ╔═╡ 7b6a3ca9-60ac-484e-a1a2-9c7e87c5719f
orient = (("R", "P", "I"))

# ╔═╡ 627fa140-9395-4470-bcea-54849cb61983
begin
	img_array = load_dcm_array(img)
	img_array, affvol, new_affvol = DICOMUtils.orientation(img_array, orient)
	img_array = permutedims(img_array, (2, 1, 3))
end;

# ╔═╡ dc2e2b3f-77e9-4845-a6e5-65547a49dd70
md"""
### 100 kV
"""

# ╔═╡ dc937793-ba7d-4e23-b55d-b73babaf68ec
image_path2 = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\49\100.0";

# ╔═╡ cf20f9dc-5776-4857-a746-acf216fe3391
label_path2 = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\HEL_SLICER_SEG_0\100\L_5.0.nii";

# ╔═╡ 8794f460-bc1b-4c74-9a2d-707fdc4acd3f
begin
	lbl_2 = niread(label_path2)
	lbl_array2 = copy(lbl_2.raw)
end;

# ╔═╡ 58f323a6-92f9-4f7f-8969-5b71c5013dd7
NIfTI.orientation(lbl_2)

# ╔═╡ a3c0cb8a-2ce6-4a29-b371-f4f194973a41
img_2 = dcmdir_parse(image_path2);

# ╔═╡ 235fa3e9-c81e-4a1e-a4ac-25236a8f895d
md"""
#### Reorient DICOM
"""

# ╔═╡ 9e07d337-a792-4349-8d6d-56f21c68d639
begin
	aff2 = get_affine(img_2)
	io2 = io_orientation(aff2)
	ornt2axcodes(io2)
end

# ╔═╡ 6718792d-7dbc-4786-8be2-724db8458b5f
begin
	img_array2 = load_dcm_array(img_2)
	img_array2, affvol2, new_affvol2 = DICOMUtils.orientation(img_array2, orient)
	img_array2 = permutedims(img_array2, (2, 1, 3))
end;

# ╔═╡ 3e804f4b-3b7d-47ac-ab58-0d3ba8662884
md"""
### Visualize images and labels
"""

# ╔═╡ 9ce79ba5-4b57-4cef-b809-90f1c01f2e3e
function collect_tuple(tuple_array)
	row_num = size(tuple_array)
	col_num = length(tuple_array[1])
	container = zeros(Int64, row_num..., col_num)
	for i in 1:length(tuple_array)
		container[i,:] = collect(tuple_array[i])
	end
	return container
end

# ╔═╡ 0879fd99-58ed-4f93-b446-ca8190a91b85
begin
	l_indices = findall(x -> x == 1.0, lbl_array)
	l_indices2 = findall(x -> x == 1.0, lbl_array2)
end;

# ╔═╡ 5158b66a-9624-4cc1-aee9-bae91cc68c11
begin
	li = Tuple.(l_indices)
	li2 = Tuple.(l_indices2)
end;

# ╔═╡ 766b6bff-2244-4577-874a-f4d640f4f321
begin
	label_arr = collect_tuple(li)
	label_arr2 = collect_tuple(li2)
end;

# ╔═╡ ea4c93e9-80eb-4e6e-8dd3-6bc675698da0
begin
	zs_l = unique(label_arr[:,3])
	zs_l2 = unique(label_arr2[:,3])
end;

# ╔═╡ caa4ed3d-47e5-4030-bb9f-0d70f791f348
@bind q PlutoUI.Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ a51aea16-bc50-4343-96d0-bba3e4333c11
@bind r PlutoUI.Slider(1:length(zs_l2), default=10, show_value=true)

# ╔═╡ 291bd287-2d82-4e1f-8325-66b7111b6b2f
begin
	indices_l = findall(x -> x == zs_l[q], label_arr[:,3])
	indices_l2 = findall(x -> x == zs_l2[r], label_arr2[:,3])
end;

# ╔═╡ b4593c55-e98f-4357-b874-fb8dfa570e5c
begin
	fig = Figure()
	ax = Makie.Axis(fig[1, 1])
	ax.title = "Large Insert (80 kV)"
	heatmap!(ax, img_array[:,:,zs_l[q]], colormap=:grays)
	scatter!(ax, label_arr[:,1][indices_l], label_arr[:,2][indices_l], markersize=1, color=:red)
	fig
end

# ╔═╡ 923fe020-e24e-4770-9814-64582460173f
begin
	fig2 = Figure()
	ax_2 = Makie.Axis(fig2[1, 1])
	ax_2.title = "Large Insert (100 kV)"
	heatmap!(ax_2, img_array2[:,:,zs_l2[r]], colormap=:grays)
	scatter!(ax_2, label_arr2[:,1][indices_l2], label_arr2[:,2][indices_l2], markersize=1, color=:red)
	fig2
end

# ╔═╡ 3cb21e2c-07e4-4e07-8331-5a0d48889072
md"""
## Calibrate
"""

# ╔═╡ 313ad781-97b0-4091-bb1a-a3534ee00b2d
md"""
### Calculate `S_BG`s
"""

# ╔═╡ 77399f48-e100-45ea-ab0a-49b39e84f904
begin
	# 80 kV
	ring = Bool.(dilate(lbl_array) - lbl_array)
	S_BG = mean(img_array[ring])
	
	# 100 kV
	ring2 = Bool.(dilate(lbl_array2) - lbl_array2)
	S_BG2 = mean(img_array2[ring2])
end

# ╔═╡ bad81568-5edc-4821-a0cb-6833f911ac0b
md"""
### Calculate `S_O`s
"""

# ╔═╡ f1361ff7-f0b5-4c91-9dfd-63474ce808ab
begin
	# 80 kV
	core = Bool.(erode(lbl_array))
	core = erode(core)
	S_O = mean(img_array[core])
	
	# 100 kV
	core2 = Bool.(erode(lbl_array2))
	core2 = erode(core2)
	S_O2 = mean(img_array2[core2])
end

# ╔═╡ 9d56d1bf-171d-4e66-a0f3-f610dfde9edd
md"""
### Visualize `S_BG` and `S_O`
"""

# ╔═╡ 105dbd69-b579-41ed-a3ce-0ea4124c547b
@bind b PlutoUI.Slider(1:size(lbl_array)[3]; default=215, show_value=true)

# ╔═╡ 019d3f86-3ee8-4615-8a62-69a93f93d5ca
begin
	f = Figure()
	ax1 = Makie.Axis(f[1, 1])
	ax1.title = "Ring 80 kV (S_BG)"
	heatmap!(ax1, ring[:, :, b])
	
	ax2 = Makie.Axis(f[1, 2])
	ax2.title = "Core 80 kV (S_O)"
	heatmap!(ax2, core[:, :, b])
	f
end

# ╔═╡ 678f6770-b606-470d-96f3-085246456f42
@bind c PlutoUI.Slider(1:size(lbl_array2)[3]; default=215, show_value=true)

# ╔═╡ 572941be-0738-4c78-9191-855b477d2755
begin
	f2 = Figure()
	ax1_2 = Makie.Axis(f2[1, 1])
	ax1_2.title = "Ring 100 kV (S_BG)"
	heatmap!(ax1_2, ring2[:, :, c])
	
	ax2_2 = Makie.Axis(f2[1, 2])
	ax2_2.title = "Core 100 kV (S_O)"
	heatmap!(ax2_2, core2[:, :, c])
	f2
end

# ╔═╡ 6e52d101-f7ac-4063-8e69-4562854639dc
md"""
## Optional: Save as CSV/Excel file
"""

# ╔═╡ f21103e4-f3ad-44ac-b877-4c95e8000a72
S_BGs, S_Os = [S_BG, S_BG2], [S_O, S_O2]

# ╔═╡ 5ef0ed13-59d6-44cb-949f-e92e26a7662b
df = DataFrame(S_BGs = S_BGs, S_Os = S_Os)

# ╔═╡ d99f04c9-7238-4e29-b108-d1298db0cc4c
# save_path = ".."

# ╔═╡ 9dbbe3cb-adb8-4abd-a6da-31b3c6ce236e
# CSV.write(save_path, df)

# ╔═╡ Cell order:
# ╠═85e8a0e3-4de3-4933-9a52-35436bbde55f
# ╠═401e5509-40bf-48f8-8593-fd4f538c6805
# ╟─baa7cd06-10e6-4f9a-8ffd-1f458253d5fb
# ╟─06db439a-134e-4484-8f10-9102cfef5352
# ╠═2fc032ad-b041-4fc4-8661-53b9fde5563d
# ╠═639cd8f6-e16a-46dd-9430-8c38ce3648ae
# ╠═dc44351b-c4fb-44e3-918e-75a87dd3fb1a
# ╠═6ebd6d62-c26b-4c72-ad90-f109f4da35f5
# ╠═8b12e0d6-1285-4bca-bf79-0c629c1aec27
# ╟─a2201222-dfb5-46d2-a40b-e36f390a2218
# ╠═1f4ab494-12e4-498b-b8fe-eabb68f9638d
# ╠═7b6a3ca9-60ac-484e-a1a2-9c7e87c5719f
# ╠═627fa140-9395-4470-bcea-54849cb61983
# ╟─dc2e2b3f-77e9-4845-a6e5-65547a49dd70
# ╠═dc937793-ba7d-4e23-b55d-b73babaf68ec
# ╠═cf20f9dc-5776-4857-a746-acf216fe3391
# ╠═8794f460-bc1b-4c74-9a2d-707fdc4acd3f
# ╠═58f323a6-92f9-4f7f-8969-5b71c5013dd7
# ╠═a3c0cb8a-2ce6-4a29-b371-f4f194973a41
# ╟─235fa3e9-c81e-4a1e-a4ac-25236a8f895d
# ╠═9e07d337-a792-4349-8d6d-56f21c68d639
# ╠═6718792d-7dbc-4786-8be2-724db8458b5f
# ╟─3e804f4b-3b7d-47ac-ab58-0d3ba8662884
# ╠═9ce79ba5-4b57-4cef-b809-90f1c01f2e3e
# ╠═0879fd99-58ed-4f93-b446-ca8190a91b85
# ╠═5158b66a-9624-4cc1-aee9-bae91cc68c11
# ╠═766b6bff-2244-4577-874a-f4d640f4f321
# ╠═ea4c93e9-80eb-4e6e-8dd3-6bc675698da0
# ╠═291bd287-2d82-4e1f-8325-66b7111b6b2f
# ╟─caa4ed3d-47e5-4030-bb9f-0d70f791f348
# ╟─b4593c55-e98f-4357-b874-fb8dfa570e5c
# ╟─a51aea16-bc50-4343-96d0-bba3e4333c11
# ╟─923fe020-e24e-4770-9814-64582460173f
# ╟─3cb21e2c-07e4-4e07-8331-5a0d48889072
# ╟─313ad781-97b0-4091-bb1a-a3534ee00b2d
# ╠═77399f48-e100-45ea-ab0a-49b39e84f904
# ╟─bad81568-5edc-4821-a0cb-6833f911ac0b
# ╠═f1361ff7-f0b5-4c91-9dfd-63474ce808ab
# ╟─9d56d1bf-171d-4e66-a0f3-f610dfde9edd
# ╟─105dbd69-b579-41ed-a3ce-0ea4124c547b
# ╟─019d3f86-3ee8-4615-8a62-69a93f93d5ca
# ╟─678f6770-b606-470d-96f3-085246456f42
# ╟─572941be-0738-4c78-9191-855b477d2755
# ╟─6e52d101-f7ac-4063-8e69-4562854639dc
# ╠═f21103e4-f3ad-44ac-b877-4c95e8000a72
# ╠═5ef0ed13-59d6-44cb-949f-e92e26a7662b
# ╠═d99f04c9-7238-4e29-b108-d1298db0cc4c
# ╠═9dbbe3cb-adb8-4abd-a6da-31b3c6ce236e
