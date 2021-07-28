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

# ╔═╡ efd96d56-a674-441d-ae0f-5d296a4069d7
begin
	let
		import Pkg
		Pkg.activate(mktempdir())
		Pkg.Registry.update()
		Pkg.add("PlutoUI")
		Pkg.add("Plots")
		Pkg.add("DICOM")
		Pkg.add("ImageMorphology")
		Pkg.add("CSV")
		Pkg.add("DataFrames")
		Pkg.add(url="https://github.com/JuliaNeuroscience/NIfTI.jl")
		Pkg.add(url="https://github.com/Dale-Black/ActiveContours.jl")
		Pkg.add(url="https://github.com/Dale-Black/DICOMUtils.jl")
	end
	
	using PlutoUI
	using Plots
	using DICOM
	using ImageMorphology
	using CSV
	using DataFrames
	using NIfTI
	using DICOMUtils
	using ActiveContours
end

# ╔═╡ 0a7fd255-7dcc-4503-8e30-479aaac148e0
TableOfContents()

# ╔═╡ 0121c734-4b75-4efd-afcc-3bc7f5d378ec
md"""
## Create ellipsoid array
"""

# ╔═╡ 8c5036b6-4888-4ba3-93b7-448f711e7565
begin
	image_shape = (50, 50, 10)
	ellipse = lazy_ellipsoid_level_set(image_shape)
	array = to_array(image_shape, ellipse)
end;

# ╔═╡ 0b581172-9067-4751-8a5b-25c5536011fe
md"""
## Skeletonize
"""

# ╔═╡ b833276e-61e2-436d-8527-ef4fd85c488c
function skeletonize3D(img)
	container = zeros(size(img))
	for z in 1:size(img)[3]
		container[:,:,z] = ImageMorphology.thinning(img[:,:,z])
	end
	return container
end

# ╔═╡ 30ff8300-7977-4e09-9f36-6025aba7d496
centerline = skeletonize3D(array);

# ╔═╡ aea60389-2491-4fb8-935d-ddd2c1a475db
md"""
## Visualize test ellipse and centerline
"""

# ╔═╡ a3b93400-1910-4779-8eef-47d8650a3b1f
function collect_tuple(tuple_array)
	row_num = size(tuple_array)
	col_num = length(tuple_array[1])
	container = zeros(Int64, row_num..., col_num)
	for i in 1:length(tuple_array)
		container[i,:] = collect(tuple_array[i])
	end
	return container
end

# ╔═╡ 2205489e-bfac-444b-a5a0-6a414887c6bf
centerline_test_indices = findall(x -> x == 1.0, centerline)

# ╔═╡ 5a9a5bee-90ff-4860-beec-e727a9d4e96a
c_test_i = Tuple.(centerline_test_indices)

# ╔═╡ 5b9061e5-5a26-4875-abfc-ab661dbddc80
c_test_arr = collect_tuple(c_test_i)

# ╔═╡ 5a9f7576-3318-441f-8e4e-c633a2537804
zs_test = unique(c_test_arr[:,3]);

# ╔═╡ e8e45f2a-7eb1-4145-9d4b-09723a4dea75
@bind t Slider(1:length(zs_test), default=1, show_value=true)

# ╔═╡ ad8e72a6-8544-40b3-a661-3b3758a4755d
indices_test = findall(x -> x == zs_test[t], c_test_arr[:,3])

# ╔═╡ 3b402c48-2b31-4e99-89a9-cc9574c4c493
begin
	plt_test = Plots.scatter(c_test_arr[:,1][indices_test], c_test_arr[:,2][indices_test], color="red", markersize=100)
	Plots.heatmap!(plt_test, transpose(array[:,:,zs_test[t]]), size=(5000, 5000), alpha=0.5, c=:grays)
end

# ╔═╡ c0633c94-1637-4e13-8167-18428badfbf9
md"""
## Load NIfTI
"""

# ╔═╡ a0021625-29b6-4b09-a137-2b8f3948e5a7
image_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\52\HR80KV120SEGMENT";

# ╔═╡ 58f7df01-98c8-4f32-a5c9-32ae256ec10d
label_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\HEL_SLICER_SEG_80\120\S_1.2.nii";

# ╔═╡ b43e68d5-6495-431d-ac7e-85f2e34ca981
begin
	lbl = niread(label_path)
	lbl_array = copy(lbl.raw)
end;

# ╔═╡ afc4de79-db18-4289-b4cb-e7498f5e6d68
unique(lbl_array)

# ╔═╡ 117a46fc-ddd8-4424-8bf9-603a615e4715
NIfTI.orientation(lbl)

# ╔═╡ c0c06f88-0a7a-44fb-b004-badd43babfd2
md"""
## Load DICOM
"""

# ╔═╡ 2a4f14fe-9221-4233-b9da-fc9e1627d65b
md"""
### Reorient DICOM
"""

# ╔═╡ 9d079413-2408-4029-9b0a-47422003bbe6
img = dcmdir_parse(image_path);

# ╔═╡ 12e160f6-7bde-491c-90ef-caafbb9807a4
begin
	aff = get_affine(img)
	io = io_orientation(aff)
	ornt2axcodes(io)
end

# ╔═╡ 2de0a71a-357a-48da-a15b-d991a737f390
orient = (("R", "P", "S"))

# ╔═╡ 769fe808-1951-4fc0-840d-11cf9b9e10b6
begin
	img_array = load_dcm_array(img)
	img_array, affvol, new_affvol = DICOMUtils.orientation(img_array, orient);
end;

# ╔═╡ 38b7d31b-38b7-4c69-8851-bfb4f1c6256e
md"""
## Visualize DICOM and segmentation (label)
"""

# ╔═╡ d8554d36-be22-41e4-98eb-708906637adf
l_indices = findall(x -> x == 1.0, lbl_array);

# ╔═╡ 972b7133-eb2d-4e51-a959-3ea1763038a5
li = Tuple.(l_indices);

# ╔═╡ 30bb465a-14ef-4344-b80f-9f90ba4dbe22
label_arr = collect_tuple(li);

# ╔═╡ c6d4527c-65a8-412f-94cf-784f8ae74b5d
zs_l = unique(label_arr[:,3]);

# ╔═╡ d46c80f4-75b3-4488-8ecb-36ab9a9dde63
@bind q Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ 435ed45e-b647-474b-851c-cee48706c475
indices_l = findall(x -> x == zs_l[q], label_arr[:,3])

# ╔═╡ 41e668d4-fc31-44d5-bb77-aae9a30a1217
begin
	plt_lbl = Plots.scatter(label_arr[:,1][indices_l], label_arr[:,2][indices_l], color="blue", alpha=0.9, markersize=1)
	Plots.heatmap!(plt_lbl, (img_array[:,:,zs_l[q]]), size=(5000, 5000), alpha=0.5, color=:grays)
end

# ╔═╡ d37d8585-6201-4ec2-9925-3e772599cd57
md"""
## Visualize label and centerlines
"""

# ╔═╡ 8c3caa0c-f427-40a3-b786-567da61bfe4a
center = skeletonize3D(Bool.(lbl_array));

# ╔═╡ 478c067a-a3ad-4ae7-880c-3c0529d98bc6
c_indices = findall(x -> x == 1.0, center);

# ╔═╡ 4ee4cfeb-1384-4979-8fa8-826c32d4b244
ci = Tuple.(c_indices);

# ╔═╡ 3ca31105-5eff-4d68-852e-54e99569ed4b
center_arr = collect_tuple(ci);

# ╔═╡ fe54df9f-c4c1-4dd5-a3a9-7c300b946a18
zs = unique(center_arr[:,3]);

# ╔═╡ 62637d09-a1b5-4f46-8ad3-792e50bd5fa4
@bind l Slider(1:length(zs), default=10, show_value=true)

# ╔═╡ eb08f166-22f8-457e-8466-288257b8d369
indices = findall(x -> x == zs[l], center_arr[:,3])

# ╔═╡ e935f1f6-c0e1-443a-9cc6-56217512eac0
begin
	plt2a = Plots.scatter(center_arr[:,1][indices], center_arr[:,2][indices], color="red", markersize=7)
	Plots.heatmap!(plt2a, transpose(lbl_array[:,:,zs[l]]), size=(7500, 5000), alpha=0.5, color=:grays)
end

# ╔═╡ 42d896a2-13b3-4895-81c7-cdfaa0cb4f33
md"""
## Visualize 3D centerline
"""

# ╔═╡ da0db005-6a65-479e-b4ec-ad62aa4b2bfa
Plots.scatter(center_arr[:,1], center_arr[:,2], center_arr[:,3], markersize=10)

# ╔═╡ 85e14e0c-b65a-44e0-84b8-f3b310f96144
md"""
## Save the centerpoints
"""

# ╔═╡ 7a718dec-3686-468f-93db-a882930aa262
cols = ["x", "y", "z"]

# ╔═╡ a4080bf8-20df-43eb-991b-4f7b01ae02f5
df = DataFrame(center_arr, cols)

# ╔═╡ a94013f3-e496-4f8e-b9ac-0675995db8bd
save_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\CONFIG 1^275\HEL_SLICER_SEG_80\120\S_1.2_centerpoints.csv"

# ╔═╡ 9cdbf130-4d01-40f9-8f6b-ef8f18203922
CSV.write(save_path, df)

# ╔═╡ Cell order:
# ╠═efd96d56-a674-441d-ae0f-5d296a4069d7
# ╠═0a7fd255-7dcc-4503-8e30-479aaac148e0
# ╟─0121c734-4b75-4efd-afcc-3bc7f5d378ec
# ╠═8c5036b6-4888-4ba3-93b7-448f711e7565
# ╟─0b581172-9067-4751-8a5b-25c5536011fe
# ╠═b833276e-61e2-436d-8527-ef4fd85c488c
# ╠═30ff8300-7977-4e09-9f36-6025aba7d496
# ╟─aea60389-2491-4fb8-935d-ddd2c1a475db
# ╠═a3b93400-1910-4779-8eef-47d8650a3b1f
# ╠═2205489e-bfac-444b-a5a0-6a414887c6bf
# ╠═5a9a5bee-90ff-4860-beec-e727a9d4e96a
# ╠═5b9061e5-5a26-4875-abfc-ab661dbddc80
# ╠═5a9f7576-3318-441f-8e4e-c633a2537804
# ╠═ad8e72a6-8544-40b3-a661-3b3758a4755d
# ╠═e8e45f2a-7eb1-4145-9d4b-09723a4dea75
# ╠═3b402c48-2b31-4e99-89a9-cc9574c4c493
# ╟─c0633c94-1637-4e13-8167-18428badfbf9
# ╠═a0021625-29b6-4b09-a137-2b8f3948e5a7
# ╠═58f7df01-98c8-4f32-a5c9-32ae256ec10d
# ╠═b43e68d5-6495-431d-ac7e-85f2e34ca981
# ╠═afc4de79-db18-4289-b4cb-e7498f5e6d68
# ╠═117a46fc-ddd8-4424-8bf9-603a615e4715
# ╟─c0c06f88-0a7a-44fb-b004-badd43babfd2
# ╟─2a4f14fe-9221-4233-b9da-fc9e1627d65b
# ╠═9d079413-2408-4029-9b0a-47422003bbe6
# ╟─12e160f6-7bde-491c-90ef-caafbb9807a4
# ╠═769fe808-1951-4fc0-840d-11cf9b9e10b6
# ╠═2de0a71a-357a-48da-a15b-d991a737f390
# ╟─38b7d31b-38b7-4c69-8851-bfb4f1c6256e
# ╠═d8554d36-be22-41e4-98eb-708906637adf
# ╠═972b7133-eb2d-4e51-a959-3ea1763038a5
# ╠═30bb465a-14ef-4344-b80f-9f90ba4dbe22
# ╠═c6d4527c-65a8-412f-94cf-784f8ae74b5d
# ╠═435ed45e-b647-474b-851c-cee48706c475
# ╠═d46c80f4-75b3-4488-8ecb-36ab9a9dde63
# ╠═41e668d4-fc31-44d5-bb77-aae9a30a1217
# ╟─d37d8585-6201-4ec2-9925-3e772599cd57
# ╠═8c3caa0c-f427-40a3-b786-567da61bfe4a
# ╠═478c067a-a3ad-4ae7-880c-3c0529d98bc6
# ╠═4ee4cfeb-1384-4979-8fa8-826c32d4b244
# ╠═3ca31105-5eff-4d68-852e-54e99569ed4b
# ╠═eb08f166-22f8-457e-8466-288257b8d369
# ╠═fe54df9f-c4c1-4dd5-a3a9-7c300b946a18
# ╠═62637d09-a1b5-4f46-8ad3-792e50bd5fa4
# ╠═e935f1f6-c0e1-443a-9cc6-56217512eac0
# ╟─42d896a2-13b3-4895-81c7-cdfaa0cb4f33
# ╠═da0db005-6a65-479e-b4ec-ad62aa4b2bfa
# ╟─85e14e0c-b65a-44e0-84b8-f3b310f96144
# ╠═7a718dec-3686-468f-93db-a882930aa262
# ╠═a4080bf8-20df-43eb-991b-4f7b01ae02f5
# ╠═a94013f3-e496-4f8e-b9ac-0675995db8bd
# ╠═9cdbf130-4d01-40f9-8f6b-ef8f18203922
