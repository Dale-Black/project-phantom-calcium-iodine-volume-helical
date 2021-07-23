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

# ╔═╡ 6f16e0ec-eb29-11eb-37bd-6fd61abf4218
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

# ╔═╡ 490e5d53-f3cd-4829-b44c-f19d0b79de88
TableOfContents()

# ╔═╡ ebd939e6-59e2-4d6b-bd14-ac6851cca936
md"""
## Load data
Currently, this notebook only loads the large segmentation. This notebook should load all three segmentations and calculate the mass for each of them all at once.
"""

# ╔═╡ 2a1309fb-4c38-4374-961d-cd63475ea17f
image_path = "/Users/daleblack/Desktop/phantom test data/CONFIG 1^275/49/100.0"

# ╔═╡ 83f34417-0a1c-4228-8026-2b9cf80889d4
label_path = "/Users/daleblack/Desktop/phantom test data/CONFIG 1^275/HEL_SLICER_SEG_0/100/L_5.0.nii"

# ╔═╡ 63cdb8fd-80a2-49b9-b9c1-22cfcad8f15c
begin
	lbl = niread(label_path)
	lbl_array = copy(lbl.raw)
end;

# ╔═╡ 66b75264-98c0-465b-8eb3-381b8d135222
NIfTI.orientation(lbl)

# ╔═╡ 0377236e-05c8-4914-8086-9fec7fbbcf5f
img = dcmdir_parse(image_path);

# ╔═╡ 8c4fce6f-41b5-4351-87d7-275a9dc310ad
md"""
### Reorient DICOM
"""

# ╔═╡ 5ff12791-1be9-4246-a235-494e182880d2
begin
	aff = get_affine(img)
	io = io_orientation(aff)
	ornt2axcodes(io)
end

# ╔═╡ 9c4d2d64-7637-4d31-b857-7c34f6596b6d
orient = (("R", "P", "I"))

# ╔═╡ 7bc37e36-e9c2-4d65-add6-8ed298be4204
begin
	img_array = load_dcm_array(img)
	img_array, affvol, new_affvol = DICOMUtils.orientation(img_array, orient)
	img_array = permutedims(img_array, (2, 1, 3))
end;

# ╔═╡ c75c2b03-dfa7-48c8-a815-3a9ae7486bd3
md"""
### Visualize image and label
"""

# ╔═╡ 78093aee-243d-4f98-b151-7684e03b0d06
l_indices = findall(x -> x == 1.0, lbl_array);

# ╔═╡ a2774228-ee41-4f9f-8f86-1d4e0e15186b
li = Tuple.(l_indices);

# ╔═╡ ccfc620c-9953-475e-a31b-2ec8b67353f6
function collect_tuple(tuple_array)
	row_num = size(tuple_array)
	col_num = length(tuple_array[1])
	container = zeros(Int64, row_num..., col_num)
	for i in 1:length(tuple_array)
		container[i,:] = collect(tuple_array[i])
	end
	return container
end

# ╔═╡ 770feb3d-2af5-4656-86ed-a247d59fe121
label_arr = collect_tuple(li);

# ╔═╡ dba13ebe-b01f-4a54-98e9-9577fc3785e3
zs_l = unique(label_arr[:,3]);

# ╔═╡ 9698e3d5-a329-41d7-83c7-d95be3fe7d73
@bind q PlutoUI.Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ 432346bc-f414-471e-a08b-518d5e72b595
indices_l = findall(x -> x == zs_l[q], label_arr[:,3]);

# ╔═╡ 37f5c1f7-8f7b-44ef-959d-f64d6dd39190
begin
	sc = Scene()
	heatmap!(sc, img_array[:,:,zs_l[q]], colormap=:grays)
	scatter!(sc, label_arr[:,1][indices_l], label_arr[:,2][indices_l], markersize=1, color=:red)
	sc
end

# ╔═╡ de3c29ef-92c1-4913-b77e-cd0037ea83ed
md"""
## Mass Calculation
"""

# ╔═╡ 3c363e17-2ed4-425a-91cb-38360cabcc0d
md"""
### Calculate `S_BG`
"""

# ╔═╡ b226f693-8dcd-4451-b48d-e2e1bec227ff
begin
	lbl1 = copy(lbl_array)
	lbl2 = copy(lbl_array)
end;

# ╔═╡ c8ce2c83-a12d-45fb-b708-7946f0fba3ef
begin
	ring = Bool.(dilate(lbl1) - lbl_array)
	S_BG = mean(img_array[ring])
end

# ╔═╡ a7bed45a-16c2-4560-ac00-92c41b86b3fd
md"""
### Calculate `S_O`
"""

# ╔═╡ e5217d89-647b-418f-938d-d2555f84ed8b
begin
	core = Bool.(erode(lbl2))
	core = erode(core)
	S_O = mean(img_array[core])
end

# ╔═╡ 85fbb667-8e59-4060-8fa7-83abaea05a5b
md"""
### Visualize `S_BG` and `S_O`
"""

# ╔═╡ da51ed6b-d390-4d12-bfe7-abb9106b86b0
@bind b PlutoUI.Slider(1:size(lbl1)[3]; default=215, show_value=true)

# ╔═╡ 45e29cb9-f669-4d56-aba7-54bf991cf867
heatmap(ring[:, :, b])

# ╔═╡ 76f26b01-0b24-4ff4-a67c-b3fdf854af71
heatmap(core[:, :, b])

# ╔═╡ a2827168-5058-499f-9b71-c9a1e4edb1a3
md"""
### Calculate voxel size
"""

# ╔═╡ 8527716f-465b-4264-975b-14c3ae4fe08c
begin
	const PixelSpacing = (0x0028, 0x0030)
	x_sz, y_sz = img[1][PixelSpacing]
end

# ╔═╡ 3a063afe-71b6-418a-b32f-a9d9ab084ca8
begin
	const SliceThickness = (0x0018, 0x0050)
	z_sz = img[1][SliceThickness]
end

# ╔═╡ 7eb4c259-ea1c-401f-9357-7519be3375be
voxel_size_mm = x_sz * y_sz * z_sz # mm^3

# ╔═╡ 1491e8b1-64ec-4ec7-9aae-56fb90070fae
md"""
### Calculate number of voxels of object
"""

# ╔═╡ 5f76c2c4-7cc0-40f1-9e4b-4b1ebdd97baf
function num_voxels(I, num_voxels_tot, S_BG, S_O)
	num_voxels_obj = (I - (num_voxels_tot * S_BG)) / (S_O - S_BG)
	return num_voxels_obj 
end

# ╔═╡ 21ce576c-58cc-4bdb-90e6-b97af45c8342
begin
	# erode label and use as mask for image
	voxel_mask = img_array[Bool.(erode(lbl1))]
	I = sum(voxel_mask)
	num_voxels_tot = length(voxel_mask)
	
	num_voxels_obj = num_voxels(I, num_voxels_tot, S_BG, S_O)
end

# ╔═╡ ee3b359b-c43e-40ea-a5fa-4dd16f2dd920
num_voxels_tot > num_voxels_obj

# ╔═╡ 1cf5bedc-dad0-474a-a4a6-e46fca551fde
md"""
### Calculate volume
"""

# ╔═╡ 297e22fb-18df-4dfe-9de0-c0668ebf93d7
begin
	vol_obj_mm = voxel_size_mm * num_voxels_obj # mm^3
	vol_obj_cm = vol_obj_mm * 0.001 # cm^3
end

# ╔═╡ 6700b739-b0b3-473d-9d49-9584537871db
md"""
### Calculate mass
"""

# ╔═╡ 1fd9030e-f450-46ac-b876-00c351b9b2f6
begin
	ρ_Ca = 1.5 # g/cm^3
	m_Ca = vol_obj_cm * ρ_Ca # g
end

# ╔═╡ 3332b7b8-625c-4440-9dad-07bfa2a3dd91
md"""
### Ground truth mass for large segmentation
"""

# ╔═╡ 6e90b4b1-1da5-40c9-8483-b73d244004bc
begin
	num_inserts = 4
	length_inserts = 7 # mm
	area_inserts = π * (5/2)^2 # mm^2
	vol_inserts_mm = length_inserts * area_inserts # mm^3
	vol_inserts_cm = vol_inserts_mm * 0.001 # mm^3
	
	gt_m_Ca = (vol_inserts_cm * ρ_Ca) * num_inserts # g
end

# ╔═╡ 29b6f23f-df2f-4ee3-8af3-fa352b3e6d3b
md"""
## Optional: Save as CSV/Excel file
"""

# ╔═╡ 55ee2d9c-d699-48d2-a414-36650f1868e3
df = DataFrame(gt_mass = gt_m_Ca, calc_mass = m_Ca)

# ╔═╡ ac220b8c-3378-4e5f-b599-ee4778f6a7e3
# save_path = ".."

# ╔═╡ 132fe985-9b67-47f2-a7a8-949f30a9cc26
# CSV.write(save_path, df)

# ╔═╡ Cell order:
# ╠═6f16e0ec-eb29-11eb-37bd-6fd61abf4218
# ╠═490e5d53-f3cd-4829-b44c-f19d0b79de88
# ╟─ebd939e6-59e2-4d6b-bd14-ac6851cca936
# ╠═2a1309fb-4c38-4374-961d-cd63475ea17f
# ╠═83f34417-0a1c-4228-8026-2b9cf80889d4
# ╠═63cdb8fd-80a2-49b9-b9c1-22cfcad8f15c
# ╠═66b75264-98c0-465b-8eb3-381b8d135222
# ╠═0377236e-05c8-4914-8086-9fec7fbbcf5f
# ╟─8c4fce6f-41b5-4351-87d7-275a9dc310ad
# ╠═5ff12791-1be9-4246-a235-494e182880d2
# ╠═9c4d2d64-7637-4d31-b857-7c34f6596b6d
# ╠═7bc37e36-e9c2-4d65-add6-8ed298be4204
# ╟─c75c2b03-dfa7-48c8-a815-3a9ae7486bd3
# ╠═78093aee-243d-4f98-b151-7684e03b0d06
# ╠═a2774228-ee41-4f9f-8f86-1d4e0e15186b
# ╠═ccfc620c-9953-475e-a31b-2ec8b67353f6
# ╠═770feb3d-2af5-4656-86ed-a247d59fe121
# ╠═dba13ebe-b01f-4a54-98e9-9577fc3785e3
# ╠═432346bc-f414-471e-a08b-518d5e72b595
# ╟─9698e3d5-a329-41d7-83c7-d95be3fe7d73
# ╠═37f5c1f7-8f7b-44ef-959d-f64d6dd39190
# ╟─de3c29ef-92c1-4913-b77e-cd0037ea83ed
# ╟─3c363e17-2ed4-425a-91cb-38360cabcc0d
# ╠═b226f693-8dcd-4451-b48d-e2e1bec227ff
# ╠═c8ce2c83-a12d-45fb-b708-7946f0fba3ef
# ╟─a7bed45a-16c2-4560-ac00-92c41b86b3fd
# ╠═e5217d89-647b-418f-938d-d2555f84ed8b
# ╟─85fbb667-8e59-4060-8fa7-83abaea05a5b
# ╠═da51ed6b-d390-4d12-bfe7-abb9106b86b0
# ╠═45e29cb9-f669-4d56-aba7-54bf991cf867
# ╠═76f26b01-0b24-4ff4-a67c-b3fdf854af71
# ╟─a2827168-5058-499f-9b71-c9a1e4edb1a3
# ╠═8527716f-465b-4264-975b-14c3ae4fe08c
# ╠═3a063afe-71b6-418a-b32f-a9d9ab084ca8
# ╠═7eb4c259-ea1c-401f-9357-7519be3375be
# ╟─1491e8b1-64ec-4ec7-9aae-56fb90070fae
# ╠═5f76c2c4-7cc0-40f1-9e4b-4b1ebdd97baf
# ╠═21ce576c-58cc-4bdb-90e6-b97af45c8342
# ╠═ee3b359b-c43e-40ea-a5fa-4dd16f2dd920
# ╟─1cf5bedc-dad0-474a-a4a6-e46fca551fde
# ╠═297e22fb-18df-4dfe-9de0-c0668ebf93d7
# ╟─6700b739-b0b3-473d-9d49-9584537871db
# ╠═1fd9030e-f450-46ac-b876-00c351b9b2f6
# ╟─3332b7b8-625c-4440-9dad-07bfa2a3dd91
# ╠═6e90b4b1-1da5-40c9-8483-b73d244004bc
# ╟─29b6f23f-df2f-4ee3-8af3-fa352b3e6d3b
# ╠═55ee2d9c-d699-48d2-a414-36650f1868e3
# ╠═ac220b8c-3378-4e5f-b599-ee4778f6a7e3
# ╠═132fe985-9b67-47f2-a7a8-949f30a9cc26
