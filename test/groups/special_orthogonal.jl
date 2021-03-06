include("../utils.jl")
include("group_utils.jl")

@testset "Special Orthogonal group" begin
    G = SpecialOrthogonal(3)
    @test repr(G) == "SpecialOrthogonal(3)"
    M = base_manifold(G)
    @test M === Rotations(3)
    x = Matrix(I, 3, 3)

    types = [Matrix{Float64}]
    ω = [[1.0, 2.0, 3.0], [3.0, 2.0, 1.0], [1.0, 3.0, 2.0]]
    pts = [exp(M, x, hat(M, x, ωi)) for ωi in ω]
    vpts = [hat(M, x, [-1.0, 2.0, 0.5]), hat(M, x, [1.0, 0.0, 0.5])]

    ge = similar(pts[1])
    copyto!(ge, Identity(G))
    @test isapprox(ge, I; atol=1e-10)

    for T in types
        gpts = convert.(T, pts)
        vgpts = convert.(T, vpts)
        @test compose(G, gpts[1], gpts[2]) ≈ gpts[1] * gpts[2]
        @test translate_diff(G, gpts[2], gpts[1], vgpts[1], LeftAction()) ≈ vgpts[1]
        @test translate_diff(G, gpts[2], gpts[1], vgpts[1], RightAction()) ≈ transpose(gpts[2]) * vgpts[1] * gpts[2]
        test_group(G, gpts, vgpts; test_diff = true)
    end

    @testset "Decorator forwards to group" begin
        DM = NotImplementedGroupDecorator(G)
        @test Manifolds.is_decorator_group(DM) === Val(true)
        @test base_group(DM) === G
        @test Identity(DM) === Identity(G)
        @test_throws DomainError is_manifold_point(DM, Identity(TranslationGroup(3)), true)
        test_group(DM, pts, vpts; test_diff = true)
    end

    @testset "Group forwards to decorated" begin
        retraction_methods = [Manifolds.PolarRetraction(),
                              Manifolds.QRRetraction()]

        inverse_retraction_methods = [Manifolds.PolarInverseRetraction(),
                                      Manifolds.QRInverseRetraction()]

        test_manifold(G, pts;
            test_reverse_diff = false,
            test_injectivity_radius = false,
            test_project_tangent = true,
            test_musical_isomorphisms = false,
            retraction_methods = retraction_methods,
            inverse_retraction_methods = inverse_retraction_methods,
            exp_log_atol_multiplier = 20,
            retraction_atol_multiplier = 12,
        )

        @test injectivity_radius(G) == injectivity_radius(M)
        @test injectivity_radius(G, pts[1]) == injectivity_radius(M, pts[1])
        @test injectivity_radius(G, pts[1], PolarRetraction()) == injectivity_radius(M, pts[1], PolarRetraction())

        y = similar(pts[1])
        exp!(G, y, pts[1], vpts[1])
        @test isapprox(M, y, exp(M, pts[1], vpts[1]))

        y = similar(pts[1])
        retract!(G, y, pts[1], vpts[1])
        @test isapprox(M, y, retract(M, pts[1], vpts[1]))

        w = similar(vpts[1])
        inverse_retract!(G, w, pts[1], pts[2])
        @test isapprox(M, pts[1], w, inverse_retract(M, pts[1], pts[2]))

        w = similar(vpts[1])
        inverse_retract!(G, w, pts[1], pts[2], QRInverseRetraction())
        @test isapprox(M, pts[1], w, inverse_retract(M, pts[1], pts[2], QRInverseRetraction()))

        z = collect(reshape(1.0:9.0, 3, 3))
        @test isapprox(M, project_point(G, z), project_point(M, z))
        z2 = similar(pts[1])
        project_point!(G, z2, z)
        @test isapprox(M, z2, project_point(M, z))
    end
end
