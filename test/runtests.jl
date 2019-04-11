using Test

using MemoryBasedCF
using SparseArrays

R = sparse([
    2.0  1.0  0.0
    1.0  0.0  2.0
    0.0  1.0  2.0
    0.0  0.0  2.0
])

@testset "default" begin
    m = memorize(R)

    @test m.nu == 4
    @test m.ni == 3
    @test m.bu == [1.5, 1.5, 1.5, 2.0]
    @test m.bi == [1.5, 1.0, 2.0]
    @test m.Dui == sparse([
         0.5  -0.5   0.0
        -0.5   0.0   0.5
         0.0  -0.5   0.5
         0.0   0.0   0.0
    ])
    @test m.Diu == sparse([
         0.5  -0.5   0.0   0.0
         0.0   0.0   0.0   0.0
         0.0   0.0   0.0   0.0
    ])
    @test isapprox(m.Sii, sparse([
         1.0  -0.5  -0.5
        -0.5   1.0  -0.5
        -0.5  -0.5   1.0
    ]), atol = 1e-2)
    @test isapprox(m.Suu, sparse([
         1.0  -1.0   0.0   0.0
        -1.0   1.0   0.0   0.0
         0.0   0.0   0.0   0.0
         0.0   0.0   0.0   0.0
    ]), atol = 1e-2)

    @testset "itembased" begin
        expected_scores = [
            2.0  1.0  1.5
            1.0  1.5  2.0
            1.5  1.0  2.0
            2.0  2.0  2.0
        ]
        expected_ranked_items = [
            1  3  2
            3  2  1
            3  1  2
            1  2  3
        ]
        expected_ranked_scores = [
            2.0  1.5  1.0
            2.0  1.5  1.0
            2.0  1.5  1.0
            2.0  2.0  2.0
        ]

        @test isapprox(itembased_scores(m, [1, 2, 3, 4]), expected_scores, atol = 1e-2)
        @test isapprox(itembased_scores(m, [1, 2], [1, 3]), expected_scores[[1, 2], [1, 3]], atol = 1e-2)

        ranked_items, ranked_scores = itembased_rankings(m, 3, [1, 2, 3, 4])
        @test ranked_items == expected_ranked_items
        @test isapprox(ranked_scores, expected_ranked_scores, atol = 1e-2)

        ranked_items, ranked_scores = itembased_rankings(m, 2, [1, 2, 3, 4])
        @test ranked_items == expected_ranked_items[:, 1:2]
        @test isapprox(ranked_scores, expected_ranked_scores[:, 1:2], atol = 1e-2)

        ranked_items, ranked_scores = itembased_rankings(m, 2, [1, 2], [1, 3])
        @test ranked_items == [1 3; 3 1]
        @test isapprox(ranked_scores, [2.0 1.5; 2.0 1.0], atol = 1e-2)
    end

    @testset "userbased" begin
        expected_scores = [
            2.0  1.0  2.0
            1.0  1.0  2.0
            1.5  1.0  2.0
            1.5  1.0  2.0
        ]
        expected_ranked_items = [
            1  3  2
            3  1  2
            3  1  2
            3  1  2
        ]
        expected_ranked_scores = [
            2.0  2.0  1.0
            2.0  1.0  1.0
            2.0  1.5  1.0
            2.0  1.5  1.0
        ]

        @test isapprox(userbased_scores(m, [1, 2, 3, 4]), expected_scores, atol = 1e-2)
        @test isapprox(userbased_scores(m, [1, 2], [1, 3]), expected_scores[[1, 2], [1, 3]], atol = 1e-2)

        ranked_items, ranked_scores = userbased_rankings(m, 3, [1, 2, 3, 4])
        @test ranked_items == expected_ranked_items
        @test isapprox(ranked_scores, expected_ranked_scores, atol = 1e-2)

        ranked_items, ranked_scores = userbased_rankings(m, 2, [1, 2, 3, 4])
        @test ranked_items == expected_ranked_items[:, 1:2]
        @test isapprox(ranked_scores, expected_ranked_scores[:, 1:2], atol = 1e-2)

        ranked_items, ranked_scores = userbased_rankings(m, 2, [1, 2], [1, 3])
        @test ranked_items == [1 3; 3 1]
        @test isapprox(ranked_scores, [2.0  2.0; 2.0  1.0], atol = 1e-2)
    end
end

@testset "centering=false" begin
    c = Config(centering = false)
    m = memorize(R, c)

    @test m.nu == 4
    @test m.ni == 3
    @test m.bu == [0.0, 0.0, 0.0, 0.0]
    @test m.bi == [0.0, 0.0, 0.0]
    @test m.Dui == sparse([
        2.0  1.0  0.0
        1.0  0.0  2.0
        0.0  1.0  2.0
        0.0  0.0  2.0
    ])
    @test m.Diu == sparse([
        2.0  1.0  0.0  0.0
        1.0  0.0  1.0  0.0
        0.0  2.0  2.0  2.0
    ])

    r2, r5, r12 = sqrt(2), sqrt(5), sqrt(12)
    @test isapprox(m.Sii, sparse([
               1.0   2/(r5*r2)  2/(r5*r12)
         2/(r2*r5)         1.0  2/(r2*r12)
        2/(r12*r5)  2/(r12*r2)         1.0
    ]), atol = 1e-2)
    @test isapprox(m.Suu, sparse([
              1.0  2/(r5*r5)  1/(r5*r5)       0.0
        2/(r5*r5)        1.0  4/(r5*r5)  4/(r5*2)
        1/(r5*r5)  4/(r5*r5)        1.0  4/(r5*2)
              0.0   4/(r5*2)   4/(r5*2)       1.0
    ]), atol = 1e-2)
end
