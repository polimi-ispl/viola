function [ Q , B ] = getQB( Tree , Cotree )
    if isscalar( fieldnames( Tree ) )
        [ Q , B ] = getUsualQB( Tree.tree , Cotree.cotree );
        Q = struct( 'Q' , Q );
        B = struct( 'B' , B );
    else
        [ Q_V , Q_I , B_V , B_I ] = getVoltCurrQB( Tree.tree_V , Cotree.cotree_V , Tree.tree_I , Cotree.cotree_I );
        Q = struct( 'Q_V' , Q_V , 'Q_I' , Q_I );
        B = struct( 'B_V' , B_V , 'B_I' , B_I );
    end
end

function [ Q , B ] = getUsualQB( tree , cotree )
    ids = [ tree.Edges.ID ; cotree.Edges.ID ];
    t = numedges( tree );
    l = numedges( cotree );
    ordTree = zeros( t , 1 );
    ordCotree = zeros( l , 1 );
    for ii = 1 : t
        ordTree( ii ) = find( tree.Edges.ID == ids( ii ) );
    end
    for ii = 1 : l
        ordCotree( ii ) = find( cotree.Edges.ID == ids( t + ii ) );
    end
    At = full( incidence( tree ) );
    Ac = full( incidence( cotree ) );
    At = At( : , ordTree );
    Ac = Ac( : , ordCotree );
    F = pinv( At ) * Ac;
    F( abs( F ) <= 1e-14 ) = 0;
    Q = [ eye( t ) , F ];
    B = [ -F' , eye( l ) ];
    save( "Data\Output\NetlistParsing\parsingResults.mat" , "Q" , "B" , "-append" );
end

function [ Q_V , Q_I , B_V , B_I ] = getVoltCurrQB( tree_V , cotree_V , tree_I , cotree_I )
    ids = [ tree_V.Edges.ID ; cotree_V.Edges.ID ];
    t = numedges( tree_V );
    l = numedges( cotree_V );
    ordTree_V = zeros( t , 1 );
    ordTree_I = zeros( t , 1 );
    ordCotree_V = zeros( l , 1 );
    ordCotree_I = zeros( l , 1 );
    for ii = 1 : t
        ordTree_V( ii ) = find( tree_V.Edges.ID == ids( ii ) );
        ordTree_I( ii ) = find( tree_I.Edges.ID == ids( ii ) );
    end
    for ii = 1 : l
        ordCotree_V( ii ) = find( cotree_V.Edges.ID == ids( t + ii ) );
        ordCotree_I( ii ) = find( cotree_I.Edges.ID == ids( t + ii ) );
    end
    At_V = full( incidence( tree_V ) ); 
    Ac_V = full( incidence( cotree_V ) ); 
    At_I = full( incidence( tree_I ) ); 
    Ac_I = full( incidence( cotree_I ) );
    At_V = At_V( : , ordTree_V );
    Ac_V = Ac_V( : , ordCotree_V );
    At_I = At_I( : , ordTree_I );
    Ac_I = Ac_I( : , ordCotree_I );
    F_V = pinv( At_V ) * Ac_V;
    F_I = pinv( At_I ) * Ac_I;
    F_V( abs( F_V ) <= 1e-14 ) = 0;
    F_I( abs( F_I ) <= 1e-14 ) = 0;
    Q_V = [ eye( t ) , F_V ];
    Q_I = [ eye( t ) , F_I ];
    B_V = [ -F_V' , eye( l ) ];
    B_I = [ -F_I' , eye( l ) ];
    save( "Data\Output\NetlistParsing\parsingResults.mat" , "Q_V" , "Q_I" , "B_V" , "B_I" , "-append" );
end