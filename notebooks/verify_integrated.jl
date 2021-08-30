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

# ╔═╡ 044050ce-e8e9-11eb-1a6c-8dd3093ad1d8
begin
	let
		using Pkg
		Pkg.activate(mktempdir())
		Pkg.Registry.update()
		Pkg.add([
				"PlutoUI"
				"CairoMakie"
				"ImageFiltering"
				"DataFrames"
				])
		Pkg.add(url="https://github.com/Dale-Black/ActiveContours.jl")
		Pkg.add(url="https://github.com/Dale-Black/CalciumScoring.jl")
	end
	
	using PlutoUI
	using CairoMakie
	using ImageFiltering
	using DataFrames
	using ActiveContours
	using CalciumScoring # contains Integrated code
end

# ╔═╡ c14572e3-8eb6-449b-905d-237b201a290b
TableOfContents()

# ╔═╡ ece9f4ab-f371-497c-8a35-4436048f8fa2
md"""
CSA formula

```math
\begin{aligned}
	I &= [(A - CSA) \times S_{BG}] + [CSA \times S_{BG}] \\
	CSA &= \frac{I - (A \times S_{BG})}{S_{O} - S_{BG}}
\end{aligned}
```
"""

# ╔═╡ 4b62e951-08af-4a2a-b5ee-f75a7074b34c
md"""
## Volumetric formula

```math
\begin{aligned}
	I &= [(N - N_{Obj}) \times S_{Bkg}] + [N_{Obj} \times S_{Obj}] \\
	N_{Obj} &= \frac{I - (N \times S_{Bkg})}{S_{Obj} - S_{BG}}
\end{aligned}
```
Where ``I`` is the integrated intensity of the volume, ``N`` is the total number of voxels, ``S_{Bkg}`` is the signal intensity of pure background, ``S_{Obj}`` is the signal intensity of the pure object
"""

# ╔═╡ bfa24adb-a26c-4280-b14b-1652e5d7ac9c
md"""
#### Set up ellipsoid
Background: -1024 HU

Object: 200 HU
"""

# ╔═╡ 48d630b2-9856-4028-ba4e-008d554fb098
volume_size = (100, 100, 100)

# ╔═╡ 17275205-2a5e-492a-b62b-5be59055aa75
begin
	e1 = lazy_ellipsoid_level_set(volume_size)
	ellipsoid = to_array(volume_size, e1)
end;

# ╔═╡ 0f86ee29-8737-4f1f-a461-6f0810a3f498
begin
	ell3D = Int64.(ellipsoid)
	ell3D[ell3D .> 0] .= 200
	ell3D[ell3D .< 1] .= -1024
	ell3D
end;

# ╔═╡ 560fb49b-8384-4e51-8f40-bff5823739b8
@bind a PlutoUI.Slider(1:size(ell3D)[3]; default=25, show_value=true)

# ╔═╡ 2b6fe240-2249-4aba-89a8-77393e930bff
heatmap(ell3D[:,:,a])

# ╔═╡ 4d6e6b06-0c3d-4b2f-8e04-7db0e71f3fad
md"""
### Ground truth
"""

# ╔═╡ 27c425be-10d6-40e5-b6ca-930b2489bfb9
begin
	voxelsize = [0.5, 0.5, 0.5] # mm^3
	ρ = 0.03 # g/mm^3
end

# ╔═╡ ba62d2bc-f9b1-44ba-b3a1-1b12153b18a8
N_Obj = length(findall(x -> x == 200, ell3D))

# ╔═╡ 361413a7-eef2-4e6f-8a99-fbe84e4bfe7e
V_Obj = N_Obj * voxelsize[1] * voxelsize[2] * voxelsize[3]

# ╔═╡ f4127223-47de-41ca-a8d6-837c3980bdab
M_Obj = V_Obj * ρ

# ╔═╡ 85c1bfc4-d8c2-474b-afde-2d58973e5e75
md"""
### Measured
"""

# ╔═╡ 4352b8a8-9c51-42fa-8bc9-3321a5279bee
begin
	alg = Integrated(ell3D)
	S_Bkg = -1024
	S_Obj = 200
end

# ╔═╡ 945e956e-0f02-4733-9331-8f9824434dff
N_Obj_calc = score(S_Bkg, S_Obj, alg)

# ╔═╡ 34a0b536-873f-4f65-8f84-731af10604a6
V_Obj_calc = score(S_Bkg, S_Obj, voxelsize, alg)

# ╔═╡ 280c5517-459b-404a-9d70-e2422c78f441
M_Obj_calc = score(S_Bkg, S_Obj, voxelsize, ρ, alg)

# ╔═╡ 3e928e68-f866-491e-a6b1-975e74ccc44f
md"""
### Added noise
"""

# ╔═╡ 30822b26-3860-4219-bc2e-3474113f0f1f
noisy_ell3D = zeros(size(ell3D));

# ╔═╡ 59dd9747-b0de-4c58-b131-38a0715ae68b
for z in 1:size(ell3D)[3]
	noisy_ell3D[:, :, z] = imfilter(ell3D[:,:,z], Kernel.gaussian(3))
end

# ╔═╡ 147ecf74-04b4-4056-9a47-aa97a401ef78
@bind b PlutoUI.Slider(1:size(noisy_ell3D)[3]; default=25, show_value=true)

# ╔═╡ 3275fa17-1bf7-4377-8a7c-359a1ebb618f
heatmap(noisy_ell3D[:, :, b])

# ╔═╡ 9d4be120-5533-4959-b87e-7da0ad28d7cd
begin
	alg2 = Integrated(noisy_ell3D)
	S_Bkg2 = -1024
	S_Obj2 = 200
end

# ╔═╡ 7bcab83d-b286-4241-be4d-0715b3889379
N_Obj_calc_noisy = score(S_Bkg2, S_Obj2, alg2)

# ╔═╡ 1a4089de-9fb4-4d2a-a2c6-d18aa615664b
V_Obj_calc_noisy = score(S_Bkg2, S_Obj2, voxelsize, alg2)

# ╔═╡ 3060b377-9217-4230-842c-f1c6586a5774
M_Obj_calc_noisy = score(S_Bkg2, S_Obj2, voxelsize, ρ, alg2)

# ╔═╡ d23102ae-50f8-47f7-8c47-01d8b4863d0a
md"""
## Results
"""

# ╔═╡ 5195a4fd-f5ff-4104-9874-d9c2ab1436ee
GT = [
	N_Obj,
	V_Obj,
	M_Obj
]

# ╔═╡ feca968b-2d19-4bae-9482-4a503b8a2d04
CALC = [
	N_Obj_calc,
	V_Obj_calc,
	M_Obj_calc
]

# ╔═╡ fc3125cf-882f-4aba-a6fc-edfcb97e16b6
NOISY = [
	N_Obj_calc_noisy,
	V_Obj_calc_noisy,
	M_Obj_calc_noisy
]

# ╔═╡ 705a003c-2663-42ed-91eb-e7959596e2fb
df = DataFrame(
	GroundTruth = GT,
	Calculated = CALC,
	Noisy = NOISY
)

# ╔═╡ bdaff7e2-ae5d-42ab-91ae-1ba327ed686e
md"""
## Test extreme
"""

# ╔═╡ f5cc9760-c961-498f-bc9a-60b739eff8cc
circle = ell3D[:,:,100];

# ╔═╡ 42b281d8-d032-4b6f-9d31-cdcd85b8ef39
noisycircle = noisy_ell3D[:,:,100];

# ╔═╡ 43a6a5f4-3d6b-4d3c-acf2-1428c99f513a
heatmap(circle)

# ╔═╡ a94922c6-ea08-4fa6-9473-2f528dbc7cd3
heatmap(noisycircle)

# ╔═╡ d0b705cb-d76c-47d4-9522-41bd173423b9
begin
	alg3 = Integrated(circle)
	alg4 = Integrated(noisycircle)
end;

# ╔═╡ af38bf85-250a-44d9-8d16-bae233dbb714
length(findall(x->x==200, circle)) # GT

# ╔═╡ 8bf26f02-32e0-49c1-9f5b-b585e5480d0c
score(S_Bkg, S_Obj, alg3) # Calculate clean

# ╔═╡ b1147c97-7a33-47ce-a508-cc31d826c5cd
score(S_Bkg, S_Obj, alg4) # Calculated noisy

# ╔═╡ 62cbf38f-9da1-4c45-8418-c5d7597d76fd
md"""
## Test 3 materials
"""

# ╔═╡ d883c716-5856-408a-b656-3dc505cf1f45
begin
	vsize = 256, 256
	e2 = lazy_ellipsoid_level_set(vsize)
	ellipsoid2 = to_array(vsize, e2)
	ell2 = Int64.(ellipsoid2)
	ell2[ell2 .> 0] .= 200 				# approximate intensity of calcium
	ell2[ell2 .< 1] .= -1024 			# intensity of pure air
	ell2[1:128, :] .= -30 				# approximate intensity of fat
end;

# ╔═╡ d0cfaca0-2bdb-42c9-bef7-36fdf179d371
ell2_3D = cat(ell2, ell2, dims=3);

# ╔═╡ 4e71107f-a0bd-4be0-a24c-6c1315a577dc
size(ell2_3D)

# ╔═╡ 4e53d9f0-b634-4f4f-a2d8-c1326e5451db
heatmap(ell2_3D[:, :, 2], colormap = :grays)

# ╔═╡ 8c7b4845-c691-456f-bd2e-ddbbb4cabce1
md"""
To get the avergage background intensity we need to calculate the number of pixels that correspond to air (-1024) and fat (-30). To do this we will work in 2D and then multiply everything by 2 after, since we have two identical slices
"""

# ╔═╡ 25a757fa-d4f3-4198-9471-0c4eaeefeb0d
begin
	vol_half_square = (128 * 128) * 2				# length * width * 2
	vol_half_circle = ((π * (128/2)^2) / 2) * 2 	# π * radius^2 / 2 * 2
	vol_air = vol_half_square - vol_half_circle 	# half square - half circle
	vol_fat = (128 * 128) * 2 						# length * width * 2
end

# ╔═╡ 1d1aaaca-862c-4df3-a92d-54eb6649f4e3
S_Bkg_avg = ((-1024*vol_air) + (-30*vol_fat)) / (vol_air + vol_fat)

# ╔═╡ 3c85eb11-02c8-4bb1-b671-ac88a9e3824f
S_Obj_avg = 200

# ╔═╡ 8f9db9b5-43b8-4d8a-910b-f09cd405c0b4
md"""
Calculate the predicted number of voxels that correspond to calcium, versus the true number of voxels that correspond to calcium
"""

# ╔═╡ 73d77c9a-65b2-4fd2-a154-4cfc6693f370
begin
	alg5 = Integrated(ell2_3D)
	pred_num = score(S_Bkg_avg, S_Obj_avg, alg5)
end

# ╔═╡ 03f692be-4a1a-4761-bf06-937389f367b8
true_num = length(findall(x -> x == 200, ell2_3D))

# ╔═╡ 14b4b7e0-fd6e-4053-af9c-63a7ead640a0
md"""
Calculate the predicted volume that corresponds to calcium, versus the true volume that corresponds to calcium
"""

# ╔═╡ 3ebaaa57-198d-4255-8404-616b4b02af3c
begin
	voxel_size = [0.5, 0.5, 0.5]
	pred_vol = score(S_Bkg_avg, S_Obj_avg, voxel_size, alg5)
end

# ╔═╡ d623d381-9704-442a-b5ef-a5394ce90739
true_vol = true_num * voxel_size[1] * voxel_size[2] * voxel_size[3]

# ╔═╡ 9ff747b6-2545-4027-a0be-655f25167d66
md"""
Calculate the predicted mass that corresponds to calcium, versus the true mass that corresponds to calcium
"""

# ╔═╡ 5ca1cfd9-505a-4ba9-888d-24513c9f3090
begin
	pred_mass = score(S_Bkg_avg, S_Obj_avg, voxel_size, ρ, alg5)
end

# ╔═╡ 0c5bd9b0-f1d5-4cee-b031-fdc9d6ebdc8c
true_mass = ρ * true_vol

# ╔═╡ Cell order:
# ╠═044050ce-e8e9-11eb-1a6c-8dd3093ad1d8
# ╠═c14572e3-8eb6-449b-905d-237b201a290b
# ╟─ece9f4ab-f371-497c-8a35-4436048f8fa2
# ╟─4b62e951-08af-4a2a-b5ee-f75a7074b34c
# ╟─bfa24adb-a26c-4280-b14b-1652e5d7ac9c
# ╠═48d630b2-9856-4028-ba4e-008d554fb098
# ╠═17275205-2a5e-492a-b62b-5be59055aa75
# ╠═0f86ee29-8737-4f1f-a461-6f0810a3f498
# ╟─560fb49b-8384-4e51-8f40-bff5823739b8
# ╠═2b6fe240-2249-4aba-89a8-77393e930bff
# ╟─4d6e6b06-0c3d-4b2f-8e04-7db0e71f3fad
# ╠═27c425be-10d6-40e5-b6ca-930b2489bfb9
# ╠═ba62d2bc-f9b1-44ba-b3a1-1b12153b18a8
# ╠═361413a7-eef2-4e6f-8a99-fbe84e4bfe7e
# ╠═f4127223-47de-41ca-a8d6-837c3980bdab
# ╟─85c1bfc4-d8c2-474b-afde-2d58973e5e75
# ╠═4352b8a8-9c51-42fa-8bc9-3321a5279bee
# ╠═945e956e-0f02-4733-9331-8f9824434dff
# ╠═34a0b536-873f-4f65-8f84-731af10604a6
# ╠═280c5517-459b-404a-9d70-e2422c78f441
# ╟─3e928e68-f866-491e-a6b1-975e74ccc44f
# ╠═30822b26-3860-4219-bc2e-3474113f0f1f
# ╠═59dd9747-b0de-4c58-b131-38a0715ae68b
# ╟─147ecf74-04b4-4056-9a47-aa97a401ef78
# ╠═3275fa17-1bf7-4377-8a7c-359a1ebb618f
# ╠═9d4be120-5533-4959-b87e-7da0ad28d7cd
# ╠═7bcab83d-b286-4241-be4d-0715b3889379
# ╠═1a4089de-9fb4-4d2a-a2c6-d18aa615664b
# ╠═3060b377-9217-4230-842c-f1c6586a5774
# ╟─d23102ae-50f8-47f7-8c47-01d8b4863d0a
# ╠═5195a4fd-f5ff-4104-9874-d9c2ab1436ee
# ╠═feca968b-2d19-4bae-9482-4a503b8a2d04
# ╠═fc3125cf-882f-4aba-a6fc-edfcb97e16b6
# ╠═705a003c-2663-42ed-91eb-e7959596e2fb
# ╟─bdaff7e2-ae5d-42ab-91ae-1ba327ed686e
# ╠═f5cc9760-c961-498f-bc9a-60b739eff8cc
# ╠═42b281d8-d032-4b6f-9d31-cdcd85b8ef39
# ╠═43a6a5f4-3d6b-4d3c-acf2-1428c99f513a
# ╠═a94922c6-ea08-4fa6-9473-2f528dbc7cd3
# ╠═d0b705cb-d76c-47d4-9522-41bd173423b9
# ╠═af38bf85-250a-44d9-8d16-bae233dbb714
# ╠═8bf26f02-32e0-49c1-9f5b-b585e5480d0c
# ╠═b1147c97-7a33-47ce-a508-cc31d826c5cd
# ╟─62cbf38f-9da1-4c45-8418-c5d7597d76fd
# ╠═d883c716-5856-408a-b656-3dc505cf1f45
# ╠═d0cfaca0-2bdb-42c9-bef7-36fdf179d371
# ╠═4e71107f-a0bd-4be0-a24c-6c1315a577dc
# ╠═4e53d9f0-b634-4f4f-a2d8-c1326e5451db
# ╟─8c7b4845-c691-456f-bd2e-ddbbb4cabce1
# ╠═25a757fa-d4f3-4198-9471-0c4eaeefeb0d
# ╠═1d1aaaca-862c-4df3-a92d-54eb6649f4e3
# ╠═3c85eb11-02c8-4bb1-b671-ac88a9e3824f
# ╟─8f9db9b5-43b8-4d8a-910b-f09cd405c0b4
# ╠═73d77c9a-65b2-4fd2-a154-4cfc6693f370
# ╠═03f692be-4a1a-4761-bf06-937389f367b8
# ╟─14b4b7e0-fd6e-4053-af9c-63a7ead640a0
# ╠═3ebaaa57-198d-4255-8404-616b4b02af3c
# ╠═d623d381-9704-442a-b5ef-a5394ce90739
# ╟─9ff747b6-2545-4027-a0be-655f25167d66
# ╠═5ca1cfd9-505a-4ba9-888d-24513c9f3090
# ╠═0c5bd9b0-f1d5-4cee-b031-fdc9d6ebdc8c
