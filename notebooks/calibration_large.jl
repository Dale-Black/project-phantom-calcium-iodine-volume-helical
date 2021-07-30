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

# ╔═╡ 4f6cd82a-0fef-4f4b-bf89-c4628714bdf9
thresh = 15

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
image_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 4^275\52\80.0";

# ╔═╡ 639cd8f6-e16a-46dd-9430-8c38ce3648ae
label_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 4^275\HEL_SLICER_SEG_0\80\L_5.0.nii";

# ╔═╡ dc44351b-c4fb-44e3-918e-75a87dd3fb1a
begin
	lbl = niread(label_path)
	lbl_array = copy(lbl.raw)
end;

# ╔═╡ 6ebd6d62-c26b-4c72-ad90-f109f4da35f5
NIfTI.orientation(lbl)

# ╔═╡ 8b12e0d6-1285-4bca-bf79-0c629c1aec27
img = dcmdir_parse(image_path);

# ╔═╡ 7b6a3ca9-60ac-484e-a1a2-9c7e87c5719f
orient = (("R", "P", "I"))

# ╔═╡ 627fa140-9395-4470-bcea-54849cb61983
begin
	# Reorient
	img_array = load_dcm_array(img)
	img_array, affvol, new_affvol = DICOMUtils.orientation(img_array, orient)
	img_array = permutedims(img_array, (2, 1, 3))
end;

# ╔═╡ dc2e2b3f-77e9-4845-a6e5-65547a49dd70
md"""
### 100 kV
"""

# ╔═╡ dc937793-ba7d-4e23-b55d-b73babaf68ec
image_path2 = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 4^275\52\100.0";

# ╔═╡ a3c0cb8a-2ce6-4a29-b371-f4f194973a41
img_2 = dcmdir_parse(image_path2);

# ╔═╡ 6718792d-7dbc-4786-8be2-724db8458b5f
begin
	# Reorient
	img_array2 = load_dcm_array(img_2)
	img_array2, affvol2, new_affvol2 = DICOMUtils.orientation(img_array2, orient)
	img_array2 = permutedims(img_array2, (2, 1, 3))
end;

# ╔═╡ 05d69d6e-f047-470a-92f4-550a01fd374f
md"""
### 120 kV
"""

# ╔═╡ 00ee0012-f44e-466c-a68e-0c5380436dd8
image_path3 = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 4^275\52\120.0";

# ╔═╡ dcf6b2cc-72c7-4322-b0ef-764d8a7590eb
img_3 = dcmdir_parse(image_path3);

# ╔═╡ 71b2bc03-ae83-4169-a26e-35addcb64770
begin
	# Reorient
	img_array3 = load_dcm_array(img_3)
	img_array3, affvol3, new_affvol3 = DICOMUtils.orientation(img_array3, orient)
	img_array3 = permutedims(img_array3, (2, 1, 3))
end;

# ╔═╡ cf85c203-79f3-488b-965e-0a0b2d44a4c6
md"""
### 135 kV
"""

# ╔═╡ e114ac6a-375b-4f29-85ab-fe917f67137d
image_path4 = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 4^275\52\135.0";

# ╔═╡ 94f63f2c-e1ca-4b9f-b65b-ab1066058e6d
img_4 = dcmdir_parse(image_path4);

# ╔═╡ f6afb134-3622-42cd-9a2e-1edda84cb4a9
begin
	# Reorient
	img_array4 = load_dcm_array(img_4)
	img_array4, affvol4, new_affvol4 = DICOMUtils.orientation(img_array4, orient)
	img_array4 = permutedims(img_array4, (2, 1, 3))
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

# ╔═╡ 01f53372-5023-4da3-a085-af823755f4b5
l_indices = findall(x -> x == 1.0, lbl_array);

# ╔═╡ 388b30ad-02f2-47ca-a76e-debb954d26d5
li = Tuple.(l_indices);

# ╔═╡ 8a3efe87-8931-4d97-a354-c4f6d0bdeebc
label_arr = collect_tuple(li);

# ╔═╡ 8ee2cb50-68c7-4efc-afec-a80b0ab698fb
zs_l = unique(label_arr[:,3]);

# ╔═╡ caa4ed3d-47e5-4030-bb9f-0d70f791f348
@bind q PlutoUI.Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ cb5ffd4d-c8fd-4b56-aa9c-5f331e18c116
indices_l = findall(x -> x == zs_l[q], label_arr[:,3]);

# ╔═╡ b4593c55-e98f-4357-b874-fb8dfa570e5c
begin
	fig = Figure()
	ax = Makie.Axis(fig[1, 1])
	ax.title = "Large Insert (80 kV)"
	heatmap!(ax, img_array[:,:,zs_l[q]], colormap=:grays)
	scatter!(ax, label_arr[:,1][indices_l], label_arr[:,2][indices_l], markersize=1, color=:red)
	
	ax_2 = Makie.Axis(fig[1, 2])
	ax_2.title = "Large Insert (100 kV)"
	heatmap!(ax_2, img_array2[:,:,zs_l[q]], colormap=:grays)
	scatter!(ax_2, label_arr[:,1][indices_l], label_arr[:,2][indices_l], markersize=1, color=:red)
	
	ax_3 = Makie.Axis(fig[2, 1])
	ax_3.title = "Large Insert (120 kV)"
	heatmap!(ax_3, img_array3[:,:,zs_l[q]], colormap=:grays)
	scatter!(ax_3, label_arr[:,1][indices_l], label_arr[:,2][indices_l], markersize=1, color=:red)
	
	ax_4 = Makie.Axis(fig[2, 2])
	ax_4.title = "Large Insert (135 kV)"
	heatmap!(ax_4, img_array3[:,:,zs_l[q]], colormap=:grays)
	scatter!(ax_4, label_arr[:,1][indices_l], label_arr[:,2][indices_l], markersize=1, color=:red)
	fig
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
	
	ring = Bool.(dilate(dilate(dilate(dilate(lbl_array)))) - dilate(lbl_array))
	
	# 80 kV
	r_img = img_array[ring]
	r_img = r_img[r_img .> thresh]
	S_BG = mean(r_img)
	
	# 100 kV
	r_img2 = img_array2[ring]
	r_img2 = r_img2[r_img2 .> thresh]
	S_BG2 = mean(r_img2)
	
	# 120 kV
	r_img3 = img_array3[ring]
	r_img3 = r_img3[r_img3 .> thresh]
	S_BG3 = mean(r_img3)
	
	# 135 kV
	r_img4 = img_array4[ring]
	r_img4 = r_img4[r_img4 .> thresh]
	S_BG4 = mean(r_img4)
end

# ╔═╡ bad81568-5edc-4821-a0cb-6833f911ac0b
md"""
### Calculate `S_O`s
"""

# ╔═╡ f1361ff7-f0b5-4c91-9dfd-63474ce808ab
begin
	
	core = Bool.((erode(erode(lbl_array))))
	
	# 80 kV
	c_img = img_array[core]
	c_img = c_img[c_img .> thresh]
	S_O = mean(c_img)
	
	# 100 kV
<<<<<<< HEAD
	c_img2 = img_array2[core]
	c_img2 = c_img2[c_img2 .> thresh]
	S_O2 = mean(c_img2)
	
	# 120 kV
	c_img3 = img_array3[core]
	c_img3 = c_img3[c_img3 .> thresh]
	S_O3 = mean(c_img3)
	
	# 135 kV
	c_img4 = img_array4[core]
	c_img4 = c_img4[c_img4 .> thresh]
	S_O4 = mean(c_img4)
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
	heatmap!(ax1, ring[:, :, b], colormap=:grays)
	
	ax2 = Makie.Axis(f[1, 2])
	ax2.title = "Core 80 kV (S_O)"
	heatmap!(ax2, core[:, :, b], colormap=:grays)
	f
end

# ╔═╡ 6e52d101-f7ac-4063-8e69-4562854639dc
md"""
## Optional: Save as CSV/Excel file
"""

# ╔═╡ f21103e4-f3ad-44ac-b877-4c95e8000a72
S_BGs, S_Os = [S_BG, S_BG2, S_BG3, S_BG4], [S_O, S_O2, S_O3, S_O4]

# ╔═╡ 5ef0ed13-59d6-44cb-949f-e92e26a7662b
df = DataFrame(S_BGs = S_BGs, S_Os = S_Os)

# ╔═╡ d99f04c9-7238-4e29-b108-d1298db0cc4c
# save_path = ".."

# ╔═╡ 9dbbe3cb-adb8-4abd-a6da-31b3c6ce236e
# CSV.write(save_path, df)

# ╔═╡ Cell order:
# ╠═85e8a0e3-4de3-4933-9a52-35436bbde55f
# ╠═401e5509-40bf-48f8-8593-fd4f538c6805
# ╠═4f6cd82a-0fef-4f4b-bf89-c4628714bdf9
# ╟─baa7cd06-10e6-4f9a-8ffd-1f458253d5fb
# ╠═2fc032ad-b041-4fc4-8661-53b9fde5563d
# ╠═dc937793-ba7d-4e23-b55d-b73babaf68ec
# ╠═00ee0012-f44e-466c-a68e-0c5380436dd8
# ╠═e114ac6a-375b-4f29-85ab-fe917f67137d
# ╠═639cd8f6-e16a-46dd-9430-8c38ce3648ae
# ╟─06db439a-134e-4484-8f10-9102cfef5352
# ╠═dc44351b-c4fb-44e3-918e-75a87dd3fb1a
# ╠═6ebd6d62-c26b-4c72-ad90-f109f4da35f5
# ╠═8b12e0d6-1285-4bca-bf79-0c629c1aec27
# ╠═7b6a3ca9-60ac-484e-a1a2-9c7e87c5719f
# ╠═627fa140-9395-4470-bcea-54849cb61983
# ╟─dc2e2b3f-77e9-4845-a6e5-65547a49dd70
# ╠═a3c0cb8a-2ce6-4a29-b371-f4f194973a41
# ╠═6718792d-7dbc-4786-8be2-724db8458b5f
# ╟─05d69d6e-f047-470a-92f4-550a01fd374f
# ╠═dcf6b2cc-72c7-4322-b0ef-764d8a7590eb
# ╠═71b2bc03-ae83-4169-a26e-35addcb64770
# ╟─cf85c203-79f3-488b-965e-0a0b2d44a4c6
# ╠═94f63f2c-e1ca-4b9f-b65b-ab1066058e6d
# ╠═f6afb134-3622-42cd-9a2e-1edda84cb4a9
# ╟─3e804f4b-3b7d-47ac-ab58-0d3ba8662884
# ╠═9ce79ba5-4b57-4cef-b809-90f1c01f2e3e
# ╠═01f53372-5023-4da3-a085-af823755f4b5
# ╠═cb5ffd4d-c8fd-4b56-aa9c-5f331e18c116
# ╠═388b30ad-02f2-47ca-a76e-debb954d26d5
# ╠═8a3efe87-8931-4d97-a354-c4f6d0bdeebc
# ╠═8ee2cb50-68c7-4efc-afec-a80b0ab698fb
# ╟─caa4ed3d-47e5-4030-bb9f-0d70f791f348
# ╠═b4593c55-e98f-4357-b874-fb8dfa570e5c
# ╟─3cb21e2c-07e4-4e07-8331-5a0d48889072
# ╟─313ad781-97b0-4091-bb1a-a3534ee00b2d
# ╠═77399f48-e100-45ea-ab0a-49b39e84f904
# ╟─bad81568-5edc-4821-a0cb-6833f911ac0b
# ╠═f1361ff7-f0b5-4c91-9dfd-63474ce808ab
# ╟─9d56d1bf-171d-4e66-a0f3-f610dfde9edd
# ╟─105dbd69-b579-41ed-a3ce-0ea4124c547b
# ╠═019d3f86-3ee8-4615-8a62-69a93f93d5ca
# ╟─6e52d101-f7ac-4063-8e69-4562854639dc
# ╠═f21103e4-f3ad-44ac-b877-4c95e8000a72
# ╠═5ef0ed13-59d6-44cb-949f-e92e26a7662b
# ╠═d99f04c9-7238-4e29-b108-d1298db0cc4c
# ╠═9dbbe3cb-adb8-4abd-a6da-31b3c6ce236e
