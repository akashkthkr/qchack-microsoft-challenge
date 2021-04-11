namespace QCHack.Task4 {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Logical;
    open Microsoft.Quantum.Math;

    // Task 4 (12 points). f(x) = 1 if the graph edge coloring is triangle-free
    // 
    // Inputs:
    //      1) The number of vertices in the graph "V" (V ≤ 6).
    //      2) An array of E tuples of integers "edges", representing the edges of the graph (0 ≤ E ≤ V(V-1)/2).
    //         Each tuple gives the indices of the start and the end vertices of the edge.
    //         The vertices are indexed 0 through V - 1.
    //         The graph is undirected, so the order of the start and the end vertices in the edge doesn't matter.
    //      3) An array of E qubits "colorsRegister" that encodes the color assignments of the edges.
    //         Each color will be 0 or 1 (stored in 1 qubit).
    //         The colors of edges in this array are given in the same order as the edges in the "edges" array.
    //      4) A qubit "target" in an arbitrary state.
    //
    // Goal: Implement a marking oracle for function f(x) = 1 if
    //       the coloring of the edges of the given graph described by this colors assignment is triangle-free, i.e.,
    //       no triangle of edges connecting 3 vertices has all three edges in the same color.
    //
    // Example: a graph with 3 vertices and 3 edges [(0, 1), (1, 2), (2, 0)] has one triangle.
    // The result of applying the operation to state (|001⟩ + |110⟩ + |111⟩)/√3 ⊗ |0⟩ 
    // will be 1/√3|001⟩ ⊗ |1⟩ + 1/√3|110⟩ ⊗ |1⟩ + 1/√3|111⟩ ⊗ |0⟩.
    // The first two terms describe triangle-free colorings, 
    // and the last term describes a coloring where all edges of the triangle have the same color.
    //
    // In this task you are not allowed to use quantum gates that use more qubits than the number of edges in the graph,
    // unless there are 3 or less edges in the graph. For example, if the graph has 4 edges, you can only use 4-qubit gates or less.
    // You are guaranteed that in tests that have 4 or more edges in the graph the number of triangles in the graph 
    // will be strictly less than the number of edges.
    //
    // Hint: Make use of helper functions and helper operations, and avoid trying to fit the complete
    //       implementation into a single operation - it's not impossible but make your code less readable.
    //       GraphColoring kata has an example of implementing oracles for a similar task.
    //
    // Hint: Remember that you can examine the inputs and the intermediary results of your computations
    //       using Message function for classical values and DumpMachine for quantum states.
    //
    operation Task4_TriangleFreeColoringOracle (
        V : Int, 
        edges : (Int, Int)[], 
        colorsRegister : Qubit[], 
        target : Qubit
    ) : Unit is Adj+Ctl {
        
        let e = Length(edges);
        if (e < 3 or V < 3) {
            X(target);
        }
        else {
            let (triangles,num_triangles) = allTriangles(edges,V);
            if (num_triangles == 0) {
                X(target);
            }
            else {
                use ancillae = Qubit[num_triangles];
                within {
                    for i in 0..num_triangles-1 {
                        let (a,b,c) = triangles[i];
                        let control = [colorsRegister[a],colorsRegister[b],colorsRegister[c]];
                        (ControlledOnBitString([true,true,true], X))(control, ancillae[i]);
                        (ControlledOnBitString([false,false,false], X))(control, ancillae[i]);
                        X(ancillae[i]);
                    }
                }
                apply {
                    Controlled X(ancillae,target);
                }
            }
        }
    }

    function allTriangles (edges: (Int,Int)[], V: Int) : ((Int,Int,Int)[],Int) {
        //O(n^3) search because I'm a lazy programmer
        let e = Length(edges);
        let max_triangles = (V*(V-1))/2;
        mutable num_triangles = 0;
        mutable triangles = new(Int,Int,Int)[max_triangles];
        for i in 0..e-1 {
            for j in i+1..e-1 {
                for k in j+1..e-1 {
                    if isTriangle(edges[i],edges[j],edges[k]) {
                        set triangles w/= num_triangles <- (i,j,k);
                        set num_triangles += 1;
                    }
                }
            }
        }
        return (triangles,num_triangles);
    }

    function isTriangle (e1: (Int, Int), e2: (Int, Int), e3: (Int, Int)) : Bool{
        let (s1,f1) = e1;
        let (s2,f2) = e2;
        let (s3,f3) = e3;
        let u = Unique(EqualI,Sorted(LessThanOrEqualI,[s1,f1,s2,f2,s3,f3]));
        return (Length(u) == 3); 
    }
}

