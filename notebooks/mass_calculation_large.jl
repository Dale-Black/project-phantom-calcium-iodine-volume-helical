### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

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

# ╔═╡ 490e5d53-f3cd-4829-b44c-f19d0b79de88
TableOfContents()

# ╔═╡ 0320ac33-16dd-4f82-9878-858d0070459e
md"""
## Input `S_BG` and `S_O`
These values come from the calibration_large.jl notebook
"""

# ╔═╡ c8ce2c83-a12d-45fb-b708-7946f0fba3ef
begin
	S_BG, S_O = -125.937, 65.5397
	S_BG2, S_O2 = -67.4193, 71.858
end;

# ╔═╡ 48a0715a-bccb-4270-9bd3-f1ec633a19bc
md"""
## Input Calcium density
"""

# ╔═╡ 3f952f50-be47-45bb-b6d4-63d7a4866969
ρ_Ca = 50 # g/cc == g/cm^3

# ╔═╡ ebd939e6-59e2-4d6b-bd14-ac6851cca936
md"""
## Load data
"""

# ╔═╡ 2a1309fb-4c38-4374-961d-cd63475ea17f
begin
	# 80 kV
	image_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\49\80.0"
	
	# 100 kV
	image_path2 = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\49\100.0"
	
	# 120 kV
	image_path3 = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\49\120.0"
end;

# ╔═╡ 83f34417-0a1c-4228-8026-2b9cf80889d4
begin
	# 80 kV
	label_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\HEL_SLICER_SEG_0\80\L_5.0.nii"
	
	# 100 kV
	label_path2 = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\HEL_SLICER_SEG_0\100\L_5.0.nii"
end;

# ╔═╡ 63cdb8fd-80a2-49b9-b9c1-22cfcad8f15c
begin
	# 80 kV
	lbl = niread(label_path)
	lbl_array = copy(lbl.raw)
	
	# 100 kV
	lbl2 = niread(label_path2)
	lbl_array2 = copy(lbl2.raw)
end;

# ╔═╡ 0377236e-05c8-4914-8086-9fec7fbbcf5f
begin
	img = dcmdir_parse(image_path)
	img2 = dcmdir_parse(image_path2)
end;

# ╔═╡ 9c4d2d64-7637-4d31-b857-7c34f6596b6d
orient = ("R", "P", "I")

# ╔═╡ 7bc37e36-e9c2-4d65-add6-8ed298be4204
begin
	img_array = load_dcm_array(img)
	img_array, affvol, new_affvol = DICOMUtils.orientation(img_array, orient)
	img_array = permutedims(img_array, (2, 1, 3))
	
	img_array2 = load_dcm_array(img2)
	img_array2, affvol2, new_affvol2 = DICOMUtils.orientation(img_array2, orient)
	img_array2 = permutedims(img_array2, (2, 1, 3))
end;

# ╔═╡ de3c29ef-92c1-4913-b77e-cd0037ea83ed
md"""
## Mass Calculation
"""

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
	# 80 kV
	# erode label and use as mask for image
	voxel_mask = img_array[Bool.(erode(lbl_array))]
	I = sum(voxel_mask)
	num_voxels_tot = length(voxel_mask)
	
	num_voxels_obj = num_voxels(I, num_voxels_tot, S_BG, S_O)
	
	# 100 kV
	# erode label and use as mask for image
	voxel_mask2 = img_array2[Bool.(erode(lbl_array2))]
	I2 = sum(voxel_mask2)
	num_voxels_tot2 = length(voxel_mask2)
	
	num_voxels_obj2 = num_voxels(I2, num_voxels_tot2, S_BG2, S_O2)
	
# 	# 120 kV
# 	# erode label and use as mask for image
# 	voxel_mask3 = img_array3[Bool.(erode(lbl_array3))]
# 	I3 = sum(voxel_mask3)
# 	num_voxels_tot3 = length(voxel_mask3)
	
# 	num_voxels_obj3 = num_voxels(I3, num_voxels_tot3, S_BG3, S_O3)
end;

# ╔═╡ 1cf5bedc-dad0-474a-a4a6-e46fca551fde
md"""
### Calculate volume
"""

# ╔═╡ 297e22fb-18df-4dfe-9de0-c0668ebf93d7
begin
	# 80 kV
	vol_obj_mm = voxel_size_mm * num_voxels_obj # mm^3
	vol_obj_cm = vol_obj_mm * 0.001 # cm^3
	
	# 100 kV
	vol_obj_mm2 = voxel_size_mm * num_voxels_obj2 # mm^3
	vol_obj_cm2 = vol_obj_mm2 * 0.001 # cm^3
end;

# ╔═╡ 6700b739-b0b3-473d-9d49-9584537871db
md"""
### Calculate mass
"""

# ╔═╡ 1fd9030e-f450-46ac-b876-00c351b9b2f6
begin
	# 80 kV
	m_Ca = vol_obj_cm * ρ_Ca # g/cc
	
	# 80 kV
	m_Ca2 = vol_obj_cm2 * ρ_Ca # g/cc
end;

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
end;

# ╔═╡ 29b6f23f-df2f-4ee3-8af3-fa352b3e6d3b
md"""
## Optional: Save as CSV/Excel file
"""

# ╔═╡ f4ed499d-19a6-4908-bf94-6582ad57fc3c
masses = [m_Ca, m_Ca2];

# ╔═╡ 55ee2d9c-d699-48d2-a414-36650f1868e3
df = DataFrame(ground_truth_mass = gt_m_Ca, calcium_mass = masses)

# ╔═╡ ac220b8c-3378-4e5f-b599-ee4778f6a7e3
# save_path = ".."

# ╔═╡ 132fe985-9b67-47f2-a7a8-949f30a9cc26
# CSV.write(save_path, df) UPDATE

# ╔═╡ c155eca3-fbce-42a1-b71c-458c17d2f767


# ╔═╡ Cell order:
# ╠═6f16e0ec-eb29-11eb-37bd-6fd61abf4218
# ╠═490e5d53-f3cd-4829-b44c-f19d0b79de88
# ╟─0320ac33-16dd-4f82-9878-858d0070459e
# ╠═c8ce2c83-a12d-45fb-b708-7946f0fba3ef
# ╟─48a0715a-bccb-4270-9bd3-f1ec633a19bc
# ╠═3f952f50-be47-45bb-b6d4-63d7a4866969
# ╟─ebd939e6-59e2-4d6b-bd14-ac6851cca936
# ╠═2a1309fb-4c38-4374-961d-cd63475ea17f
# ╠═83f34417-0a1c-4228-8026-2b9cf80889d4
# ╠═63cdb8fd-80a2-49b9-b9c1-22cfcad8f15c
# ╠═0377236e-05c8-4914-8086-9fec7fbbcf5f
# ╠═9c4d2d64-7637-4d31-b857-7c34f6596b6d
# ╠═7bc37e36-e9c2-4d65-add6-8ed298be4204
# ╟─de3c29ef-92c1-4913-b77e-cd0037ea83ed
# ╟─a2827168-5058-499f-9b71-c9a1e4edb1a3
# ╠═8527716f-465b-4264-975b-14c3ae4fe08c
# ╠═3a063afe-71b6-418a-b32f-a9d9ab084ca8
# ╠═7eb4c259-ea1c-401f-9357-7519be3375be
# ╟─1491e8b1-64ec-4ec7-9aae-56fb90070fae
# ╠═5f76c2c4-7cc0-40f1-9e4b-4b1ebdd97baf
# ╠═21ce576c-58cc-4bdb-90e6-b97af45c8342
# ╟─1cf5bedc-dad0-474a-a4a6-e46fca551fde
# ╠═297e22fb-18df-4dfe-9de0-c0668ebf93d7
# ╟─6700b739-b0b3-473d-9d49-9584537871db
# ╠═1fd9030e-f450-46ac-b876-00c351b9b2f6
# ╟─3332b7b8-625c-4440-9dad-07bfa2a3dd91
# ╠═6e90b4b1-1da5-40c9-8483-b73d244004bc
# ╟─29b6f23f-df2f-4ee3-8af3-fa352b3e6d3b
# ╠═f4ed499d-19a6-4908-bf94-6582ad57fc3c
# ╠═55ee2d9c-d699-48d2-a414-36650f1868e3
# ╠═ac220b8c-3378-4e5f-b599-ee4778f6a7e3
# ╠═132fe985-9b67-47f2-a7a8-949f30a9cc26
# ╠═c155eca3-fbce-42a1-b71c-458c17d2f767
