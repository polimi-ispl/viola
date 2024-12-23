function [ Tree , Cotree ] = getTreeCotree( Graph )
    if isscalar( fieldnames( Graph ) )
        [ tree , cotree ] = findUsualTreeCotree( Graph.G );
        Tree = struct( 'tree' , tree );
        Cotree = struct( 'cotree' , cotree );
    else
        [ tree_V , cotree_V , tree_I , cotree_I ] = findCommTreeCotree( Graph.G_V , Graph.G_I );
        Tree = struct( 'tree_V' , tree_V , 'tree_I' , tree_I );
        Cotree = struct( 'cotree_V' , cotree_V , 'cotree_I' , cotree_I );
    end
end

function [ tree , cotree ] = findUsualTreeCotree( G )
    table_tree = cell2table( cell( 0 , 5 ) , 'VariableNames' , { 'EndNodes' , 'Type' , 'TypeNumber' , 'ID' , 'Parameters' } );
    nEl = numedges( G );
    elIdx = randperm( nEl , nEl );
    kk = 1;
    ii = size( table_tree , 1 ) + 1;
    while ii < numnodes( G )
        row = G.Edges( elIdx( kk ) , : );
        table_tree = [ table_tree ; row ];
        tree = graph( table_tree );
        if hascycles( tree )
            table_tree( end , : ) = [ ];
            kk = kk + 1;
        else
            elIdx( kk ) = [ ];
            ii = ii + 1;
            kk = 1;
        end
    end
    tree = digraph( table_tree );
    idx_tree = find( ismember( G.Edges.ID , tree.Edges.ID ) );
    cotree = rmedge( G , idx_tree );
end

function [ tree_V , cotree_V , tree_I , cotree_I ] = findCommTreeCotree( G_V , G_I )
    table_tree_V = cell2table( cell( 0 , 5 ) , 'VariableNames' , { 'EndNodes' , 'Type' , 'TypeNumber' , 'ID' , 'Parameters' } );
    table_tree_I = cell2table( cell( 0 , 5 ) , 'VariableNames' , { 'EndNodes' , 'Type' , 'TypeNumber' , 'ID' , 'Parameters' } );
    nEl = numedges( G_V );
    elIdx = randperm( nEl , nEl );
    kk = 1;
    ii = size( table_tree_V , 1 ) + 1;
    while ii < numnodes( G_V )
        row_V = G_V.Edges( elIdx( kk ) , : );
        row_I = G_I.Edges( G_I.Edges.ID == row_V.ID , : );
        table_tree_V = [ table_tree_V ; row_V ];
        table_tree_I = [ table_tree_I ; row_I ];
        tree_V = graph( table_tree_V );
        tree_I = graph( table_tree_I );   
        if hascycles( tree_V ) || hascycles( tree_I )
            table_tree_V( end , : ) = [ ];
            table_tree_I( end , : ) = [ ];
            kk = kk + 1;
        else
            elIdx( kk ) = [ ];
            kk = 1;
            ii = ii + 1;
        end
        if kk > length( elIdx )
            table_tree_V = cell2table( cell( 0 , 5 ) , 'VariableNames' , { 'EndNodes' , 'Type' , 'TypeNumber' , 'ID' , 'Parameters' } );
            table_tree_I = cell2table( cell( 0 , 5 ) , 'VariableNames' , { 'EndNodes' , 'Type' , 'TypeNumber' , 'ID' , 'Parameters' } );
            elIdx = randperm( nEl , nEl );
            kk = 1;
            ii = 1;
        end
    end
    tree_V = digraph( table_tree_V );
    tree_I = digraph( table_tree_I );
    idx_tree_V = find( ismember( G_V.Edges.ID , tree_V.Edges.ID ) );
    idx_tree_I = find( ismember( G_I.Edges.ID , tree_I.Edges.ID ) );
    cotree_V = rmedge( G_V , idx_tree_V );
    cotree_I = rmedge( G_I , idx_tree_I );
end
