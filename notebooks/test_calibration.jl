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

# ╔═╡ 3ad36990-0046-11ec-237b-1700383703a5
begin
	let
		using Pkg
		Pkg.activate(mktempdir())
		Pkg.Registry.update()
		Pkg.add([
				"PlutoUI"
				"BenchmarkTools"
				"CairoMakie"
				"DICOM"
				"Images"
				"ImageMorphology"
				"DataFrames"
				"CSV"
				"StatsBase"
				])
		Pkg.add([
				Pkg.PackageSpec(url="https://github.com/JuliaNeuroscience/NIfTI.jl")
				Pkg.PackageSpec(url="https://github.com/Dale-Black/IntegratedHU.jl")
				Pkg.PackageSpec(url="https://github.com/Dale-Black/DICOMUtils.jl")
				Pkg.PackageSpec(url="https://github.com/Dale-Black/CalciumScoring.jl")
				])
	end

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
	using CSV
	using StatsBase
	using CalciumScoring
end

# ╔═╡ ef22a2cb-1d13-4de6-a10b-a44c915f0847
TableOfContents()

# ╔═╡ 64624ffe-0b2a-4eec-b447-fd1ad09111f9
md"""
## Load data
"""

# ╔═╡ 67862837-8a94-4adf-89c1-e0b19a64f145
image_path = "/Users/daleblack/Desktop/phantom test data/CONFIG 1^275/49/100.0"

# ╔═╡ ffe8a60d-0c08-40cc-bc6f-af3d86b2f34a
label_path = "/Users/daleblack/Desktop/phantom test data/CONFIG 1^275/HEL_SLICER_SEG_0/100/L_5.0.nii"

# ╔═╡ c04fcfe6-d3ac-4333-a469-883dc4ab81ec
begin
	lbl = niread(label_path)
	lbl_array = copy(lbl.raw)
end;

# ╔═╡ 6014e581-60f4-4d26-97e4-e2d478df987a
img = dcmdir_parse(image_path);

# ╔═╡ 383243e9-818e-4f3d-8a10-8ecd8ebe652b
orient = (("R", "P", "I"))

# ╔═╡ 632eb914-f5ca-4f70-8796-f743ef84ff4c
begin
	# Reorient
	img_array = load_dcm_array(img)
	img_array, affvol, new_affvol = DICOMUtils.orientation(img_array, orient)
	img_array = permutedims(img_array, (2, 1, 3))
end;

# ╔═╡ 831587ea-4121-4d56-856c-4239fa710b19
md"""
## Visualize
"""

# ╔═╡ 1a0a48e7-0632-426b-872d-7a4045547db5
function collect_tuple(tuple_array)
	row_num = size(tuple_array)
	col_num = length(tuple_array[1])
	container = zeros(Int64, row_num..., col_num)
	for i in 1:length(tuple_array)
		container[i,:] = collect(tuple_array[i])
	end
	return container
end

# ╔═╡ 7db51c3f-a9e9-41a9-91e3-c5a3ae968e90
l_indices = findall(x -> x == 1.0, lbl_array);

# ╔═╡ 8a79f665-a2f6-4f55-aa10-162b94917ded
li = Tuple.(l_indices);

# ╔═╡ 7f847303-7306-4580-ad22-2c7591525bf9
label_arr = collect_tuple(li);

# ╔═╡ 67dcd624-604f-4b75-9cfe-f80a41126e3e
zs_l = unique(label_arr[:,3]);

# ╔═╡ 97f3208d-425c-4434-9d1f-3f86272dcb01
@bind q PlutoUI.Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ 76eb2b56-528b-49f1-a2ce-b3988f879287
indices_l = findall(x -> x == zs_l[q], label_arr[:,3]);

# ╔═╡ edde14ca-1073-4cc4-aac4-3bc1a1b4cb98
begin
	fig = Figure()
	
	ax = Makie.Axis(fig[1, 1])
	ax.title = "Large Insert (100 kV)"
	heatmap!(ax, img_array[:,:,zs_l[q]], colormap=:grays)
	scatter!(ax, label_arr[:,1][indices_l], label_arr[:,2][indices_l], markersize=1, color=:red)
	fig
end

# ╔═╡ b43b1e2d-9851-439b-a964-03390ec020f2
md"""
## Threshold
"""

# ╔═╡ e06cf7f0-39ce-4918-98c0-4fdfac6e8e6f
md"""
### Ring `S_Bkg`
"""

# ╔═╡ fd2b0dfa-fe8c-4f4d-992e-a0015be8eb14
md"""
First, segment out the ring that will used for the background measurement. Use the label to get the coordinates within the DICOM image that correspond to the ring. For visualization purposes and for use within `mask_elements` we need to then keep all of the original voxel values that correspond to the `true` or `1` on the binary label and fill in the rest of the voxel values with -1024 (this corresponds to air in CT images)
"""

# ╔═╡ c5713f81-881d-4058-82ac-211534c4560d
begin
	ring = Bool.((dilate(dilate(dilate(dilate(dilate(lbl_array)))))) - dilate(dilate(dilate(dilate(lbl_array)))))
	idxs = findall(x -> x == 1, ring)
	ring_img = fill(-1024, size(lbl_array))
	ring_img[idxs] .= copy(img_array[idxs])
end

# ╔═╡ bee114ab-fe3d-422a-9934-2c6192d7d115
md"""
Now let's use the original `ring` segmentation (which includes only air, background, and noise) to find a suitable threshold in which to segment out the air
"""

# ╔═╡ d5544765-491c-4faa-a0c3-60d6c3fd5e0d
cp = img_array[ring]

# ╔═╡ 71c683db-d7ab-43bb-bcb5-422fb9b3a466
md"""
The histogram below is showing all the values of the voxels contained within the ring. I would like to find a more exact approach to turn this into a normal distribution by thresholding out the x-percentile values but that doesn't work using `StatsBase.percentile`
"""

# ╔═╡ 8ae10475-302d-46e1-ae00-59a74e125e6f
hist(cp; bins=100)

# ╔═╡ df55c0ad-f712-4961-963b-6f406b8f0d69
thresh_old = mean(cp) - std(cp)

# ╔═╡ 16873eef-7fd0-4b4c-adc5-5ca692ac42d4
StatsBase.percentile(cp, 1.0) # investigate this

# ╔═╡ 17624dda-b1eb-467d-8f76-fa4fdaf07187
md"""
This is something worth investigating. Not sure why taking the x-percentile of `cp` doesn't give us a good cutoff value for the `cp_new`??

After thresholding, the new histogram of the ring/background values looks like a good normal distribution. We can use this to determine a good threshold to be used in `mask_elements` based on the mean and standard deviation
"""

# ╔═╡ d09f8a52-4dd2-4a32-ad39-c0dbe2ea05b2
cp_new = cp[cp .> -160] # arbitrary but gives a decent looking normal distribution

# ╔═╡ 36878ceb-5962-4ed8-868a-ed77aef27f22
hist(cp_new; bins=100)

# ╔═╡ 70bda50a-b94a-4a30-9d3e-226681edaa2b
thresh_new = mean(cp_new) - 0.5 * std(cp_new)

# ╔═╡ faeca5ba-d327-40ab-b408-34e7bfe6bb52
begin
	thresh_new_ring = mask_elements(ring_img, thresh_new, 3)
	idxs_new = findall(x -> x == 1, thresh_new_ring)
	thresh_ring_img = fill(-1024, size(lbl_array))
	thresh_ring_img[idxs_new] .= copy(ring_img[idxs_new])
end

# ╔═╡ 5b5b0cfb-69e2-453d-a423-b87224e4b9e9
md"""
Now, let's visualize what the original ring looks like compared to the thresholded ring
"""

# ╔═╡ a6861a61-1634-40f6-83a6-016b0a1166d5
@bind a PlutoUI.Slider(1:size(ring_img)[3]; default=224, show_value=true)

# ╔═╡ a718590c-1b2f-4ced-afe9-ef7edc52a96c
heatmap(ring_img[:, :, a])

# ╔═╡ 61d3ad2e-3073-42b9-8bd1-8620663f490b
heatmap(thresh_ring_img[:, :, a])

# ╔═╡ 95b94948-1c60-4d74-9c5e-da6b2d3929fa
S_Bkg = mean(thresh_ring_img[thresh_ring_img .> -1024])

# ╔═╡ 475e2ae9-15ab-438f-950d-1dd6a6f0fd69
md"""
### Core `S_Obj`
"""

# ╔═╡ 1a871074-2965-45bb-8a57-1bd0b66170bf
md"""
We will take the same approach as above and threshold using histograms as guides. The erosion operation looks like it does a pretty good job of removing the surrounding tissue so we don't need to threshold out the core anymore. We can use the mean and standard deviation of the eroded core as our guide for thresholding
"""

# ╔═╡ e1c67fb5-c71e-4cfa-9e3d-4c0601d9c352
begin
	core = Bool.(erode(erode(lbl_array)))
	idxs3 = findall(x -> x == 1, core)
	core_img = fill(-1024, size(lbl_array))
	core_img[idxs3] .= copy(img_array[idxs3])
end

# ╔═╡ 8fa9b4c0-8870-4b11-92ac-b3e74e1736ca
cp2 = img_array[core]

# ╔═╡ c7e24f1f-9e22-4b3b-8a52-e79dbebab2b9
hist(cp2, bins=100)

# ╔═╡ 0dd64da1-9b85-4770-8be5-c91b0a8db720
thresh2 = mean(cp2) - 0.5 * std(cp2)

# ╔═╡ 55738453-4f82-472d-988e-98c8b91a3453
begin
	thresh_new_core = mask_elements(core_img, thresh2, 3)
	idxs4 = findall(x -> x == 1, thresh_new_core)
	thresh_core_img = fill(-1024, size(lbl_array))
	thresh_core_img[idxs4] .= copy(core_img[idxs4])
end

# ╔═╡ 41da1d08-1d5e-4256-980d-cfcbfb4e1e17
@bind b PlutoUI.Slider(1:size(core_img)[3]; default=215, show_value=true)

# ╔═╡ e9b7ee17-db54-47ad-b7ed-027d658dd84e
heatmap(core_img[:, :, b])

# ╔═╡ 224826ad-9977-405d-8561-7172fe4ddf22
heatmap(thresh_core_img[:, :, b])

# ╔═╡ e9eb1a88-e1d5-417a-9a90-40424379a5fb
S_Obj = mean(thresh_core_img[thresh_core_img .> -1024])

# ╔═╡ cf615ad2-3bc6-492a-aa53-c7e703c3badc
md"""
## Calculate
"""

# ╔═╡ 722973db-5c13-415a-8be4-019c828bbeca
md"""
### `Algorithm`
"""

# ╔═╡ 6f2d3ac7-3bdb-4cf7-8191-88da59fbf1c6
begin
	bool = dilate(lbl_array)
	idxs5 = findall(x -> x == 1, bool)
	vol = fill(-1024, size(lbl_array))
	vol[idxs5] .= copy(img_array[idxs5])
end

# ╔═╡ aa101d21-aff7-42c4-bba5-532a4d821bf7
begin
	thresh_new_vol = mask_elements(vol, thresh_new, 3) # use S_Bkg threshold
	idxs6 = findall(x -> x == 1, thresh_new_vol)
	thresh_core_vol = fill(-1024, size(lbl_array))
	thresh_core_vol[idxs6] .= copy(vol[idxs6])
end

# ╔═╡ fc6f8cfa-4d6a-4692-9073-82c9ccd7ff94
@bind c PlutoUI.Slider(1:size(thresh_core_vol)[3]; default=215, show_value=true)

# ╔═╡ d02991e8-8fd1-4183-bd75-81c7baf590e6
heatmap(thresh_core_vol[:, :, c])

# ╔═╡ 2bfd9e02-8763-491d-803b-23e83d9b2372
vol2 = img_array[thresh_core_vol .> -1024]

# ╔═╡ af9687e9-b91b-41a0-a363-e26505100ba9
alg2 = Integrated(vol2)

# ╔═╡ 4e781e52-5ec0-4e81-a2af-993f507e347c
md"""
### `N_Obj`
"""

# ╔═╡ b8f30afe-d583-42f2-a2ae-36107c1abf58
N_Obj = CalciumScoring.score(S_Bkg, S_Obj, alg2)

# ╔═╡ ace0db0b-fc77-4026-9dfe-ebad4834e7e7
md"""
### `V_Obj`
"""

# ╔═╡ 80719316-69db-4600-bd2f-6bd8497bb2a1
vsize = voxel_size(lbl.header)

# ╔═╡ 4a72e6d8-983a-4137-a276-0c6e73644f27
V_Obj = CalciumScoring.score(S_Bkg, S_Obj, vsize, alg2)  # mm^3

# ╔═╡ 1cfc6984-e3a7-426e-a637-9de7e1ba9064
md"""
### `M_Obj`
"""

# ╔═╡ 56d67dfd-4f1c-4117-9c53-1225407f8304
begin
	ρ_cm = 50 # g/cm^3
	ρ_mm = ρ_cm / 1000 # g/mm^3
end

# ╔═╡ 36942fdf-435c-4a0a-9c8b-59ce295837f9
M_Obj = CalciumScoring.score(S_Bkg, S_Obj, vsize, ρ_mm, alg2)

# ╔═╡ fbf9b5a4-b21b-49c7-ad99-5d85db593fc2
md"""
### Ground truth
"""

# ╔═╡ 79aaca51-7bf3-4902-987c-4cb52a61ebf5
mass = (π * (2.5)^2) * 7 * ρ_mm # (area) * (length) * (density)

# ╔═╡ Cell order:
# ╠═3ad36990-0046-11ec-237b-1700383703a5
# ╠═ef22a2cb-1d13-4de6-a10b-a44c915f0847
# ╟─64624ffe-0b2a-4eec-b447-fd1ad09111f9
# ╠═67862837-8a94-4adf-89c1-e0b19a64f145
# ╠═ffe8a60d-0c08-40cc-bc6f-af3d86b2f34a
# ╠═c04fcfe6-d3ac-4333-a469-883dc4ab81ec
# ╠═6014e581-60f4-4d26-97e4-e2d478df987a
# ╠═383243e9-818e-4f3d-8a10-8ecd8ebe652b
# ╠═632eb914-f5ca-4f70-8796-f743ef84ff4c
# ╟─831587ea-4121-4d56-856c-4239fa710b19
# ╠═1a0a48e7-0632-426b-872d-7a4045547db5
# ╠═7db51c3f-a9e9-41a9-91e3-c5a3ae968e90
# ╠═8a79f665-a2f6-4f55-aa10-162b94917ded
# ╠═7f847303-7306-4580-ad22-2c7591525bf9
# ╠═67dcd624-604f-4b75-9cfe-f80a41126e3e
# ╠═76eb2b56-528b-49f1-a2ce-b3988f879287
# ╠═97f3208d-425c-4434-9d1f-3f86272dcb01
# ╠═edde14ca-1073-4cc4-aac4-3bc1a1b4cb98
# ╟─b43b1e2d-9851-439b-a964-03390ec020f2
# ╟─e06cf7f0-39ce-4918-98c0-4fdfac6e8e6f
# ╟─fd2b0dfa-fe8c-4f4d-992e-a0015be8eb14
# ╠═c5713f81-881d-4058-82ac-211534c4560d
# ╟─bee114ab-fe3d-422a-9934-2c6192d7d115
# ╠═d5544765-491c-4faa-a0c3-60d6c3fd5e0d
# ╟─71c683db-d7ab-43bb-bcb5-422fb9b3a466
# ╠═8ae10475-302d-46e1-ae00-59a74e125e6f
# ╠═df55c0ad-f712-4961-963b-6f406b8f0d69
# ╠═16873eef-7fd0-4b4c-adc5-5ca692ac42d4
# ╟─17624dda-b1eb-467d-8f76-fa4fdaf07187
# ╠═d09f8a52-4dd2-4a32-ad39-c0dbe2ea05b2
# ╠═36878ceb-5962-4ed8-868a-ed77aef27f22
# ╠═70bda50a-b94a-4a30-9d3e-226681edaa2b
# ╠═faeca5ba-d327-40ab-b408-34e7bfe6bb52
# ╟─5b5b0cfb-69e2-453d-a423-b87224e4b9e9
# ╟─a6861a61-1634-40f6-83a6-016b0a1166d5
# ╠═a718590c-1b2f-4ced-afe9-ef7edc52a96c
# ╠═61d3ad2e-3073-42b9-8bd1-8620663f490b
# ╠═95b94948-1c60-4d74-9c5e-da6b2d3929fa
# ╟─475e2ae9-15ab-438f-950d-1dd6a6f0fd69
# ╟─1a871074-2965-45bb-8a57-1bd0b66170bf
# ╠═e1c67fb5-c71e-4cfa-9e3d-4c0601d9c352
# ╠═8fa9b4c0-8870-4b11-92ac-b3e74e1736ca
# ╠═c7e24f1f-9e22-4b3b-8a52-e79dbebab2b9
# ╠═0dd64da1-9b85-4770-8be5-c91b0a8db720
# ╠═55738453-4f82-472d-988e-98c8b91a3453
# ╟─41da1d08-1d5e-4256-980d-cfcbfb4e1e17
# ╠═e9b7ee17-db54-47ad-b7ed-027d658dd84e
# ╠═224826ad-9977-405d-8561-7172fe4ddf22
# ╠═e9eb1a88-e1d5-417a-9a90-40424379a5fb
# ╟─cf615ad2-3bc6-492a-aa53-c7e703c3badc
# ╟─722973db-5c13-415a-8be4-019c828bbeca
# ╠═6f2d3ac7-3bdb-4cf7-8191-88da59fbf1c6
# ╠═aa101d21-aff7-42c4-bba5-532a4d821bf7
# ╟─fc6f8cfa-4d6a-4692-9073-82c9ccd7ff94
# ╠═d02991e8-8fd1-4183-bd75-81c7baf590e6
# ╠═2bfd9e02-8763-491d-803b-23e83d9b2372
# ╠═af9687e9-b91b-41a0-a363-e26505100ba9
# ╟─4e781e52-5ec0-4e81-a2af-993f507e347c
# ╠═b8f30afe-d583-42f2-a2ae-36107c1abf58
# ╟─ace0db0b-fc77-4026-9dfe-ebad4834e7e7
# ╠═80719316-69db-4600-bd2f-6bd8497bb2a1
# ╠═4a72e6d8-983a-4137-a276-0c6e73644f27
# ╟─1cfc6984-e3a7-426e-a637-9de7e1ba9064
# ╠═56d67dfd-4f1c-4117-9c53-1225407f8304
# ╠═36942fdf-435c-4a0a-9c8b-59ce295837f9
# ╟─fbf9b5a4-b21b-49c7-ad99-5d85db593fc2
# ╠═79aaca51-7bf3-4902-987c-4cb52a61ebf5
