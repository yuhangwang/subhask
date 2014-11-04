{-# LANGUAGE CPP,MagicHash,UnboxedTuples #-}

-- | This module defines the algebraic type-classes used in subhask.
-- The class hierarchies are significantly more general than those in the standard Prelude.
module SubHask.Algebra
    (
    -- * Comparisons
    Eq (..)
    , InfSemilattice (..)
    , law_InfSemilattice_commutative
    , law_InfSemilattice_associative
    , theorem_InfSemilattice_idempotent
    , SupSemilattice (..)
    , law_SupSemilattice_commutative
    , law_SupSemilattice_associative
    , theorem_SupSemilattice_idempotent
    , Lattice (..)
    , law_Lattice_infabsorption
    , law_Lattice_supabsorption
    , supremum
    , infimum
    , MinBound (..)
    , law_MinBound_inf
    , disjoint
    , MaxBound (..)
    , law_MaxBound_sup
    , Bounded
    , Heyting (..)
    , law_Heyting_maxbound
    , law_Heyting_infleft
    , law_Heyting_infright
    , law_Heyting_distributive
    , Boolean (..)
    , law_Boolean_infcomplement
    , law_Boolean_supcomplement
    , law_Boolean_infdistributivity
    , law_Boolean_supdistributivity
    , BooleanRing (..)

    , POrd (..)
    , law_POrd_reflexivity
    , law_POrd_antisymmetry
    , law_POrd_transitivity
    , defn_POrd_pcompare
    , defn_POrd_greaterthan
    , defn_POrd_lessthaninf
    , defn_POrd_lessthansup
    , POrdering (..)
    , Graded (..)
    , Ord (..)
    , law_Ord_totality
    , defn_Ord_compare
    , maximum
    , minimum
    , Ordering (..)
    , WithPreludeOrd (..)
--     , FoldableOrd (..)
    , Enum (..)

    -- ** Boolean helpers
    , (||)
    , (&&)
    , true
    , false
    , and
    , or

    -- * Set-like
    , Container (..)
    , empty
    , law_Container_preservation
    , law_Container_empty
    , Unfoldable (..)
    , insert
    , fromString
    , law_Unfoldable_cons
    , law_Unfoldable_snoc
    , Foldable (..)
    , Lexical (..)
    , length
    , reduce
    , foldtList
    , concat
    , headMaybe
    , tailMaybe
    , lastMaybe
    , initMaybe
    , Indexed (..)
    , IndexedFoldable (..)
    , IndexedUnfoldable (..)
    , IndexedDeletable (..)
    , insertAt

    , Topology (..)
    , FreeMonoid

    -- * Maybe
    , CanError (..)
    , Maybe' (..)

    -- * Number-like
    -- ** Classes with one operator
    , Semigroup (..)
    , law_Semigroup_associativity
    , Cancellative (..)
    , law_Cancellative_rightminus1
    , law_Cancellative_rightminus2
    , Monoid (..)
    , law_Monoid_leftid
    , law_Monoid_rightid
    , Abelian (..)
    , law_Abelian_commutative
    , Group (..)
    , defn_Group_negateminus
    , law_Group_leftinverse
    , law_Group_rightinverse
--     , AbelianGroup

    -- ** Classes with two operators
    , Rg(..)
    , law_Rg_multiplicativeAssociativity
    , law_Rg_multiplicativeCommutivity
    , law_Rg_annihilation
    , law_Rg_distributivityLeft
    , theorem_Rg_distributivityRight
    , Rig(..)
    , law_Rig_multiplicativeId
    , Rng
    , defn_Ring_fromInteger
    , Ring(..)
    , Integral(..)
    , law_Integral_divMod
    , law_Integral_quotRem
    , law_Integral_toFromInverse
    , fromIntegral
    , Field(..)
    , BoundedField(..)
    , infinity
    , negInfinity
    , Floating (..)
    , QuotientField(..)

    -- ** Linear algebra
    , Scalar
    , IsScalar
    , HasScalar
    , Cone (..)
    , Module (..)
    , VectorSpace (..)
    , InnerProductSpace (..)
    , innerProductDistance
    , innerProductNorm
    , OuterProductSpace (..)

    -- ** Sizes
    , Normed (..)
    , MetricSpace (..)
    , law_MetricSpace_nonnegativity
    , law_MetricSpace_indiscernables
    , law_MetricSpace_symmetry
    , law_MetricSpace_triangle

    -- * Examples
    , IndexedVector (..)
    , Set
    )
    where

import Control.Monad -- required for deriving clauses
import qualified Prelude as P
import qualified Data.List as L

import Prelude (Eq(..), Ordering (..))
import Data.Ratio
import Data.Typeable
import Test.QuickCheck (Arbitrary (..), frequency)

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set

import SubHask.Internal.Prelude
import SubHask.Category

-------------------------------------------------------------------------------
-- relational classes

{-
-- | Equivalence classes.
--
-- NOTE: IEEE 754 floating point types break the invariants because @NaN /= NaN@.
class Eq a where
    infix 4 ==
    (==) :: a -> a -> Bool

    {-# INLINE (/=) #-}
    infix 4 /=
    (/=) :: a -> a -> Bool
    a1 /= a2 = not $ a1 == a2

instance Eq Bool        where {-# INLINE (==) #-} (==) = (P.==)
instance Eq Char        where (==) = (P.==)
instance Eq Int         where (==) = (P.==)
instance Eq Integer     where (==) = (P.==)
instance Eq Float       where (==) = (P.==)
instance Eq Double      where (==) = (P.==)
instance Eq Rational    where (==) = (P.==)

instance Eq TypeRep     where (==) = (P.==)

instance Eq a => Eq [a] where
    (==) [] [] = True
    (==) [] _  = False
    (==) _  [] = False
    (==) (x:xs) (y:ys) = x==y && xs==ys

instance Eq a => Eq (Maybe a) where
    Nothing   == Nothing   = True
    (Just a1) == (Just a2) = a1==a2
    _         == _         = False

instance Eq a => Eq (Maybe' a) where
    Nothing'   == Nothing'   = True
    (Just' a1) == (Just' a2) = a1==a2
    _          == _          = False


instance Eq () where
    ()==() = True

instance (Eq a, Eq b) => Eq (a,b) where
    (a1,b1)==(a2,b2) = a1==a2 && b1==b2

instance (Eq a, Eq b, Eq c) => Eq (a,b,c) where
    (a1,b1,c1)==(a2,b2,c2) = a1==a2 && b1==b2 && c1==c2

instance (Eq a, Eq b, Eq c, Eq d) => Eq (a,b,c,d) where
    (a1,b1,c1,d1)==(a2,b2,c2,d2) = a1==a2 && b1==b2 && c1==c2 && d1==d2
-}

---------------------------------------

-- | Partial ordering
--
data POrdering
    = PLT
    | PGT
    | PEQ
    | PNA
    deriving (Read,Show)

instance Arbitrary POrdering where
    arbitrary = frequency
        [ (1, return PLT)
        , (1, return PGT)
        , (1, return PEQ)
        , (1, return PNA)
        ]

instance Eq POrdering where
    PLT == PLT = True
    PGT == PGT = True
    PEQ == PEQ = True
    PNA == PNA = True
    _   == _   = False

-- | FIXME: think carefully about the correct instance for this
instance Semigroup POrdering where
    PEQ + x = x
    PLT + _ = PLT
    PGT + _ = PGT
    PNA + _ = PNA

instance Semigroup Ordering where
    EQ + x = x
    LT + _ = LT
    GT + _ = GT

instance Monoid POrdering where
    zero = PEQ

instance Monoid Ordering where
    zero = EQ

--  | Old instance below; I hope nothing relied on this
--     PLT + PLT = PLT
--     PLT + PEQ = PLT
--
--     PGT + PEQ = PGT
--     PGT + PGT = PGT
--
--     PEQ + PLT = PLT
--     PEQ + PEQ = PEQ
--     PEQ + PGT = PGT
--
--     _ + _ = PNA

-- | Partial ordering.
--
-- NOTE: IEEE 754 floating point types break the invariants because @NaN /= NaN@.
--
-- TODO: Is it worth adding the complexity of a preorder? https://en.wikipedia.org/wiki/Preorder
--
class Eq a => POrd a where
    pcompare :: a -> a -> POrdering

    infix 4 <
    (<) :: a -> a -> Bool
    a1 < a2 = case pcompare a1 a2 of
        PLT -> True
        otherwise -> False

    infix 4 <=
    (<=) :: a -> a -> Bool
    a1 <= a2 = case pcompare a1 a2 of
        PLT -> True
        PEQ -> True
        otherwise -> False

    infix 4 >
    (>) :: a -> a -> Bool
    a1 > a2 = case pcompare a1 a2 of
        PGT -> True
        otherwise -> False

    infix 4 >=
    (>=) :: a -> a -> Bool
    a1 >= a2 = case pcompare a1 a2 of
        PGT -> True
        PEQ -> True
        otherwise -> False

law_POrd_reflexivity :: POrd a => a -> Bool
law_POrd_reflexivity a = a<=a

law_POrd_antisymmetry :: POrd a => a -> a -> Bool
law_POrd_antisymmetry a1 a2
    | a1 <= a2 && a2 <= a1 = a1 == a2
    | otherwise = True

law_POrd_transitivity :: POrd a => a -> a -> a -> Bool
law_POrd_transitivity  a1 a2 a3
    | a1 <= a2 && a2 <= a3 = a1 <= a3
    | a1 <= a3 && a3 <= a2 = a1 <= a2
    | a2 <= a1 && a1 <= a3 = a2 <= a3
    | a2 <= a3 && a3 <= a1 = a2 <= a1
    | a3 <= a2 && a2 <= a1 = a3 <= a1
    | a3 <= a1 && a1 <= a2 = a3 <= a2
    | otherwise = True

defn_POrd_pcompare :: POrd a => a -> a -> Bool
defn_POrd_pcompare a1 a2 = case pcompare a1 a2 of
    PEQ -> a1 == a2 && a1 >= a2 && a1 <= a2 && not (a1 > a2) && not (a1 < a2)
    PLT -> a1 < a2 && a1 <= a2 && a1 /= a2 && not (a1 >= a2) && not (a1 > a2)
    PGT -> a1 > a2 && a1 >= a2 && a1 /= a2 && not (a1 <= a2) && not (a1 < a2)
    PNA -> not (a1==a2 || a1 <= a2 || a1 < a2 || a1 > a2 || a1 >= a2)

defn_POrd_greaterthan :: POrd a => a -> a -> Bool
defn_POrd_greaterthan a1 a2
    | a1 < a2 = a2 >= a1
    | a1 > a2 = a2 <= a1
    | otherwise = True

-- | A chain is a collection of elements all of which can be compared
isChain :: POrd a => [a] -> Bool
isChain [] = True
isChain (x:xs) = all (/=PNA) (map (pcompare x) xs) && isAntichain xs

-- | An antichain is a collection of elements none of which can be compared
--
-- See <http://en.wikipedia.org/wiki/Antichain wikipedia> for more details.
--
-- See also the article on <http://en.wikipedia.org/wiki/Dilworth%27s_theorem Dilward's Theorem>.
isAntichain :: POrd a => [a] -> Bool
isAntichain [] = True
isAntichain (x:xs) = all (==PNA) (map (pcompare x) xs) && isAntichain xs

preludeOrdering2POrdering :: P.Ordering -> POrdering
preludeOrdering2POrdering P.LT = PLT
preludeOrdering2POrdering P.GT = PGT
preludeOrdering2POrdering P.EQ = PEQ

#define mkPOrd(x)\
instance POrd x where\
    pcompare a1 a2 = preludeOrdering2POrdering $ P.compare a1 a2;\
    (<)  = (P.<)        ;\
    (<=) = (P.<=)       ;\
    (>)  = (P.>)        ;\
    (>=) = (P.>=)

mkPOrd(Char)
mkPOrd(Int)
mkPOrd(Integer)
mkPOrd(Float)
mkPOrd(Double)
mkPOrd(Rational)

instance POrd Bool where
    pcompare False True  = PLT
    pcompare True  False = PGT
    pcompare False False = PEQ
    pcompare True  True  = PEQ

-------------------

-- class Ord b => WellOrdered b where
--     succ :: b -> b

-- | Graded
--
-- See <https://en.wikipedia.org/wiki/Graded_poset wikipedia> for more details.
class POrd b => Graded b where
    pred :: b -> b

    (<.) :: b -> b -> Bool
    b1 <. b2 = b1 < b2 && b1 == pred b2

instance Graded Bool    where pred = P.pred
instance Graded Char    where pred = P.pred
instance Graded Int     where pred = P.pred
instance Graded Integer where pred = P.pred

---------------------------------------

-- | This is the class of total orderings.
--
-- See https://en.wikipedia.org/wiki/Total_order
class (Lattice a, POrd a) => Ord a where
    compare :: a -> a -> Ordering
    compare a1 a2 = case pcompare a1 a2 of
        PLT -> LT
        PGT -> GT
        PEQ -> EQ
        PNA -> error "PNA given by pcompare on a totally ordered type"

    {-# INLINE min #-}
    min :: a -> a -> a
    min = inf

    {-# INLINE max #-}
    max :: a -> a -> a
    max = sup

law_Ord_totality :: Ord a => a -> a -> Bool
law_Ord_totality a1 a2 = a1 <= a2 || a2 <= a1

defn_Ord_compare :: Ord a => a -> a -> Bool
defn_Ord_compare a1 a2 = case (compare a1 a2, pcompare a1 a2) of
    (LT,PLT) -> True
    (GT,PGT) -> True
    (EQ,PEQ) -> True
    _        -> False

{-# INLINE maximum #-}
maximum :: (MinBound b, Ord b) => [b] -> b
maximum = supremum

{-# INLINE minimum #-}
minimum :: (MaxBound b, Ord b) => [b] -> b
minimum = infimum

newtype WithPreludeOrd a = WithPreludeOrd a
    deriving (Read,Show,NFData,Eq,POrd,Ord,InfSemilattice,SupSemilattice,Lattice)

instance Ord a => P.Ord (WithPreludeOrd a) where
    compare (WithPreludeOrd a1) (WithPreludeOrd a2) = compare a1 a2

-- preludeOrdering2Ordering :: P.Ordering -> Ordering
-- preludeOrdering2Ordering P.LT = LT
-- preludeOrdering2Ordering P.GT = GT
-- preludeOrdering2Ordering P.EQ = EQ
--
-- instance Ord Char       where compare a1 a2 = preludeOrdering2Ordering $ P.compare a1 a2
-- instance Ord Int        where compare a1 a2 = preludeOrdering2Ordering $ P.compare a1 a2
-- instance Ord Integer    where compare a1 a2 = preludeOrdering2Ordering $ P.compare a1 a2
-- instance Ord Float      where compare a1 a2 = preludeOrdering2Ordering $ P.compare a1 a2
-- instance Ord Double     where compare a1 a2 = preludeOrdering2Ordering $ P.compare a1 a2
-- instance Ord Rational   where compare a1 a2 = preludeOrdering2Ordering $ P.compare a1 a2

instance Ord Char       where compare = P.compare
instance Ord Int        where compare = P.compare
instance Ord Integer    where compare = P.compare
instance Ord Float      where compare = P.compare
instance Ord Double     where compare = P.compare
instance Ord Rational   where compare = P.compare

instance Ord Bool where
    compare False False = EQ
    compare True  True  = EQ
    compare False True  = LT
    compare True  False = GT

-------------------

-- | FIXME: implement this based on the Prelude class
class (Graded b, Ord b) => Enum b where


-------------------

-- | This is more commonly known as a "meet" semilattice
class InfSemilattice b where
    inf :: b -> b -> b

law_InfSemilattice_commutative :: (Eq b, InfSemilattice b) => b -> b -> Bool
law_InfSemilattice_commutative b1 b2 = inf b1 b2 == inf b2 b1

law_InfSemilattice_associative :: (Eq b, InfSemilattice b) => b -> b -> b -> Bool
law_InfSemilattice_associative b1 b2 b3 = inf (inf b1 b2) b3 == inf b1 (inf b2 b3)

theorem_InfSemilattice_idempotent :: (Eq b, InfSemilattice b) => b -> Bool
theorem_InfSemilattice_idempotent b = inf b b == b

defn_POrd_lessthaninf :: (InfSemilattice a, POrd a) => a -> a -> Bool
defn_POrd_lessthaninf a1 a2 = case pcompare a1 a2 of
    PEQ -> inf a1 a2 == a1
    PLT -> inf a1 a2 == a1
    PGT -> inf a1 a2 == a2
    PNA -> inf a1 a2 /= a1 && inf a1 a2 /= a2

instance InfSemilattice Bool       where inf = (P.&&)
instance InfSemilattice Char       where inf = P.min
instance InfSemilattice Int        where inf = P.min
instance InfSemilattice Integer    where inf = P.min
instance InfSemilattice Float      where inf = P.min
instance InfSemilattice Double     where inf = P.min
instance InfSemilattice Rational   where inf = P.min

instance InfSemilattice b => InfSemilattice (a -> b) where
    inf f g = \x -> inf (f x) (g x)

-- | This is more commonly known as a "join" semilattice
class SupSemilattice b where
    sup :: b -> b -> b

law_SupSemilattice_commutative :: (Eq b, SupSemilattice b) => b -> b -> Bool
law_SupSemilattice_commutative b1 b2 = sup b1 b2 == sup b2 b1

law_SupSemilattice_associative :: (Eq b, SupSemilattice b) => b -> b -> b -> Bool
law_SupSemilattice_associative b1 b2 b3 = sup (sup b1 b2) b3 == sup b1 (sup b2 b3)

theorem_SupSemilattice_idempotent :: (Eq b, SupSemilattice b) => b -> Bool
theorem_SupSemilattice_idempotent b = sup b b == b

defn_POrd_lessthansup :: (SupSemilattice a, POrd a) => a -> a -> Bool
defn_POrd_lessthansup a1 a2 = case pcompare a1 a2 of
    PEQ -> sup a1 a2 == a1
    PLT -> sup a1 a2 == a2
    PGT -> sup a1 a2 == a1
    PNA -> sup a1 a2 /= a1 && sup a1 a2 /= a2

instance SupSemilattice Bool       where sup = (P.||)
instance SupSemilattice Char       where sup = P.max
instance SupSemilattice Int        where sup = P.max
instance SupSemilattice Integer    where sup = P.max
instance SupSemilattice Float      where sup = P.max
instance SupSemilattice Double     where sup = P.max
instance SupSemilattice Rational   where sup = P.max

instance SupSemilattice b => SupSemilattice (a -> b) where
    sup f g = \x -> sup (f x) (g x)
-- |
--
-- Every lattice induces a unique partial ordering.
-- So we would like to have a POrd constraint on Lattice.
-- Unfortunately, this is awkward because we also want to have `a -> b` be a lattice.
-- But actually computing the partial ordering on two functions is undecidable in general (whereas computing their inf/sup is decidable).
-- By using two separate classes, we allow the `a -> b` lattice instance and guarantee that whenever you see a comparison operator that the comparison is decidable.
--
-- See <https://en.wikipedia.org/wiki/Lattice_%28order%29 wikipedia> for more details.
class (InfSemilattice b, SupSemilattice b) => Lattice b where

law_Lattice_infabsorption :: (Eq b, Lattice b) => b -> b -> Bool
law_Lattice_infabsorption b1 b2 = inf b1 (sup b1 b2) == b1

law_Lattice_supabsorption :: (Eq b, Lattice b) => b -> b -> Bool
law_Lattice_supabsorption b1 b2 = sup b1 (inf b1 b2) == b1

{-# INLINE (&&) #-}
infixr 3 &&
(&&) :: Lattice b => b -> b -> b
(&&) = inf

{-# INLINE (||) #-}
infixr 2 ||
(||) :: Lattice b => b -> b -> b
(||) = sup

{-# INLINE and #-}
and :: (Foldable bs, Elem bs~b, Boolean b) => bs -> b
and = foldl' inf true

{-# INLINE or #-}
or :: (Foldable bs, Elem bs~b, Boolean b) => bs -> b
or = foldl' sup false

{-# INLINE supremum #-}
supremum :: (Foldable bs, Elem bs~b, Lattice b, MinBound b) => bs -> b
supremum = foldl' sup minBound

{-# INLINE infimum #-}
infimum :: (Foldable bs, Elem bs~b, Lattice b, MaxBound b) => bs -> b
infimum = foldl' inf maxBound

instance Lattice Bool
instance Lattice Char
instance Lattice Int
instance Lattice Integer
instance Lattice Float
instance Lattice Double
instance Lattice Rational
instance Lattice b => Lattice (a -> b)

-------------------

-- | Most Lattice literature only considers 'Bounded' lattices, but here we have both upper and lower bounded lattices.
--
-- prop> minBound <= b || not (minBound > b)
--
class InfSemilattice b => MinBound b where
    minBound :: b

law_MinBound_inf :: (Eq b, MinBound b) => b -> Bool
law_MinBound_inf b = inf b minBound == minBound

-- | "false" is an upper bound because `a && false = false` for all a.
false :: MinBound b => b
false = minBound

-- | Two sets are disjoint if their infimum is the empty set.
-- This function generalizes the notion of disjointness for any lower bounded lattice.
-- FIXME: add other notions of disjoint
disjoint :: (Eq b, MinBound b) => b -> b -> Bool
disjoint b1 b2 = (inf b1 b2) == minBound

instance MinBound Bool where minBound = False
instance MinBound Char where minBound = P.minBound
instance MinBound Int where minBound = P.minBound
instance MinBound Float where minBound = -1/0 -- FIXME: should be a primop for this
instance MinBound Double where minBound = -1/0

instance MinBound b => MinBound (a -> b) where minBound = \x -> minBound
instance POrd a => MinBound [a] where minBound = []

-------------------

-- | Most Lattice literature only considers 'Bounded' lattices, but here we have both upper and lower bounded lattices.
--
-- prop> maxBound >= b || not (minBound < b)
--
class SupSemilattice b => MaxBound b where
    maxBound :: b

law_MaxBound_sup :: (Eq b, MaxBound b) => b -> Bool
law_MaxBound_sup b = sup b maxBound == maxBound

-- | "true" is an lower bound because `a && true = true` for all a.
true :: MaxBound b => b
true = maxBound

instance MaxBound Bool where maxBound = True
instance MaxBound Char where maxBound = P.maxBound
instance MaxBound Int where maxBound = P.maxBound
instance MaxBound Float where maxBound = 1/0 -- FIXME: should be a primop for infinity
instance MaxBound Double where maxBound = 1/0
instance MaxBound b => MaxBound (a -> b) where maxBound = \x -> maxBound

-------------------

-- | FIXME: originally, Bounded was defined as:
--
-- > type Bounded b = (Lattice b, MinBound b, MaxBound b)
--
-- But template haskell can't handle tuple types, so we rewrite it as a class/instance pair.
-- Which should it actually be?!
class (Lattice b, MinBound b, MaxBound b) => Bounded b
instance (Lattice b, MinBound b, MaxBound b) => Bounded b

-- | Heyting algebras are lattices that support implication, but not necessarily the law of excluded middle.
--
-- FIXME:
-- Is every Heyting algebra a cancellative Abelian semigroup?
-- If so, should we make that explicit in the class hierarchy?
--
-- ==== Laws
-- There is a single, simple law that Heyting algebras must satisfy:
--
-- prop> a ==> b = c   ===>   a && c < b
--
-- ==== Theorems
-- From the laws, we automatically get the properties of:
--
-- distributivity
--
-- See <https://en.wikipedia.org/wiki/Heyting_algebra wikipedia> for more details.
class Bounded b => Heyting b where
    -- | FIXME: think carefully about infix
    infixl 3 ==>
    (==>) :: b -> b -> b

law_Heyting_maxbound :: (Eq b, Heyting b) => b -> Bool
law_Heyting_maxbound b = (b ==> b) == maxBound

law_Heyting_infleft :: (Eq b, Heyting b) => b -> b -> Bool
law_Heyting_infleft b1 b2 = (b1 && (b1 ==> b2)) == (b1 && b2)

law_Heyting_infright :: (Eq b, Heyting b) => b -> b -> Bool
law_Heyting_infright b1 b2 = (b2 && (b1 ==> b2)) == b2

law_Heyting_distributive :: (Eq b, Heyting b) => b -> b -> b -> Bool
law_Heyting_distributive b1 b2 b3 = (b1 ==> (b2 && b3)) == ((b1 ==> b2) && (b1 ==> b3))

-- | FIXME: add the axioms for intuitionist logic, which are theorems based on these laws
--

-- | Modus ponens gives us a default definition for "==>" in a "Boolean" algebra.
-- This formula is guaranteed to not work in a "Heyting" algebra that is not "Boolean".
--
-- See <https://en.wikipedia.org/wiki/Modus_ponens wikipedia> for more details.
modusPonens :: Boolean b => b -> b -> b
modusPonens b1 b2 = not b1 || b2

instance Heyting Bool where (==>) = modusPonens
instance Heyting b => Heyting (a -> b) where f ==> g = \a -> f a ==> g a

-- | Generalizes Boolean variables.
--
-- See <https://en.wikipedia.org/wiki/Boolean_algebra_%28structure%29 wikipedia> for more details.
class Heyting b => Boolean b where
    not :: b -> b

law_Boolean_infcomplement :: (Eq b, Boolean b) => b -> Bool
law_Boolean_infcomplement b = (b || not b) == true

law_Boolean_supcomplement :: (Eq b, Boolean b) => b -> Bool
law_Boolean_supcomplement b = (b && not b) == false

law_Boolean_infdistributivity :: (Eq b, Boolean b) => b -> b -> b -> Bool
law_Boolean_infdistributivity b1 b2 b3 = (b1 || (b2 && b3)) == ((b1 || b2) && (b1 || b3))

law_Boolean_supdistributivity :: (Eq b, Boolean b) => b -> b -> b -> Bool
law_Boolean_supdistributivity b1 b2 b3 = (b1 && (b2 || b3)) == ((b1 && b2) || (b1 && b3))

instance Boolean Bool where not = P.not
instance Boolean b => Boolean (a -> b) where not f = \x -> not $ f x

---------

-- | A Boolean algebra is a special type of Ring.
-- Their applications (set-like operations) tend to be very different than Rings, so it makes sense for the class hierarchies to be completely unrelated.
-- The "BooleanRing" type, however, provides the correct transformation.
newtype BooleanRing b = BooleanRing b
    deriving (Read,Show,Arbitrary,NFData,Eq)

mkBooleanRing :: Boolean b => b -> BooleanRing b
mkBooleanRing = BooleanRing

instance Boolean b => Semigroup (BooleanRing b) where
--     (BooleanRing b1)+(BooleanRing b2) = BooleanRing $ (b1 && not b2) || (not b1 && b2)
    (BooleanRing b1)+(BooleanRing b2) = BooleanRing $ (b1 || b2) && not (b1 && b2)

instance Boolean b => Abelian (BooleanRing b)

instance Boolean b => Monoid (BooleanRing b) where
    zero = BooleanRing $ false

instance Boolean b => Cancellative (BooleanRing b) where
    (-)=(+)
--     b1-b2 = b1+negate b2

instance Boolean b => Group (BooleanRing b) where
    negate = id
--     negate (BooleanRing b) = BooleanRing $ not b

instance Boolean b => Rg (BooleanRing b) where
    (BooleanRing b1)*(BooleanRing b2) = BooleanRing $ b1 && b2

instance Boolean b => Rig (BooleanRing b) where
    one = BooleanRing $ true

instance Boolean b => Ring (BooleanRing b)

-------------------------------------------------------------------------------
-- numeric classes

class Semigroup g where
    infixl 6 +
    (+) :: g -> g -> g

    -- | this quantity is related to the concept of machine precision and floating point error
--     associativeEpsilon :: Ring (Scalar g) => g -> Scalar g
--     associativeEpsilon _ = 0

law_Semigroup_associativity :: ( Eq g, Semigroup g ) => g -> g -> g -> Bool
law_Semigroup_associativity g1 g2 g3 = g1 + (g2 + g3) == (g1 + g2) + g3

-- theorem_Semigroup_associativity ::
--     ( Ring (Scalar g)
--     , Eq (Scalar g)
--     , Eq g
--     , Semigroup g
--     ) => g -> g -> g -> Bool
-- theorem_Semigroup_associativity g1 g2 g3 = if associativeEpsilon g1==0
--     then g1 + (g2 + g3) == (g1 + g2) + g3
--     else True
--
-- law_Semigroup_epsilonAssociativity ::
--     ( Semigroup g
--     , Normed g
--     , Field (Scalar g)
--     ) => g -> g -> g -> Bool
-- law_Semigroup_epsilonAssociativity g1 g2 g3
--     = relativeSemigroupError g1 g2 g3 < associativeEpsilon g1

relativeSemigroupError ::
    ( Semigroup g
    , Normed g
    , Field (Scalar g)
    ) => g -> g -> g -> Scalar g
relativeSemigroupError g1 g2 g3
    = abs (   g1 + ( g2    + g3 ) )
    / abs ( ( g1 +   g2  ) + g3   )

-- | A generalization of 'Data.List.cycle' to an arbitrary 'Semigroup'.
-- May fail to terminate for some values in some semigroups.
cycle :: Semigroup m => m -> m
cycle xs = xs' where xs' = xs + xs'

instance Semigroup Int      where (+) = (P.+)
instance Semigroup Integer  where (+) = (P.+)
instance Semigroup Float    where (+) = (P.+)
instance Semigroup Double   where (+) = (P.+)
instance Semigroup Rational where (+) = (P.+)

instance Semigroup a => Semigroup (Maybe a) where
    (Just a1) + (Just a2) = Just $ a1+a2
    Nothing   + a2        = a2
    a1        + Nothing   = a1

instance Semigroup a => Semigroup (Maybe' a) where
    (Just' a1) + (Just' a2) = Just' $ a1+a2
    Nothing'   + a2         = a2
    a1         + Nothing'   = a1

instance Semigroup () where
    ()+() = ()

instance (Semigroup a, Semigroup b) => Semigroup (a,b) where
    (a1,b1)+(a2,b2) = (a1+a2,b1+b2)

instance (Semigroup a, Semigroup b, Semigroup c) => Semigroup (a,b,c) where
    (a1,b1,c1)+(a2,b2,c2) = (a1+a2,b1+b2,c1+c2)

instance (Semigroup a, Semigroup b, Semigroup c, Semigroup d) => Semigroup (a,b,c,d) where
    (a1,b1,c1,d1)+(a2,b2,c2,d2) = (a1+a2,b1+b2,c1+c2,d1+d2)

instance Semigroup   b => Semigroup   (a -> b) where f+g = \a -> f a + g a

---------------------------------------

class Semigroup g => Monoid g where
    zero :: g

law_Monoid_leftid :: (Monoid g, Eq g) => g -> Bool
law_Monoid_leftid g = zero + g == g

law_Monoid_rightid :: (Monoid g, Eq g) => g -> Bool
law_Monoid_rightid g = g + zero == g

---------

instance Monoid Int       where zero = 0
instance Monoid Integer   where zero = 0
instance Monoid Float     where zero = 0
instance Monoid Double    where zero = 0
instance Monoid Rational  where zero = 0

instance Semigroup a => Monoid (Maybe a) where
    zero = Nothing

instance Semigroup a => Monoid (Maybe' a) where
    zero = Nothing'

instance Monoid () where
    zero = ()

instance (Monoid a, Monoid b) => Monoid (a,b) where
    zero = (zero,zero)

instance (Monoid a, Monoid b, Monoid c) => Monoid (a,b,c) where
    zero = (zero,zero,zero)

instance (Monoid a, Monoid b, Monoid c, Monoid d) => Monoid (a,b,c,d) where
    zero = (zero,zero,zero,zero)

instance Monoid      b => Monoid      (a -> b) where zero = \a -> zero

---------------------------------------

-- | In a cancellative semigroup,
--
-- 1)
--
-- > a + b = a + c   ==>   b = c
-- so
-- > (a + b) - b = a + (b - b) = a
--
-- 2)
--
-- > b + a = c + a   ==>   b = c
-- so
-- > -b + (b + a) = (-b + b) + a = a
--
-- This allows us to define "subtraction" in the semigroup.
-- If the semigroup is embeddable in a group, subtraction can be thought of as performing the group subtraction and projecting the result back into the domain of the cancellative semigroup.
-- It is an open problem to fully characterize which cancellative semigroups can be embedded into groups.
--
-- See <http://en.wikipedia.org/wiki/Cancellative_semigroup wikipedia> for more details.
class Semigroup g => Cancellative g where
    infixl 6 -
    (-) :: g -> g -> g

law_Cancellative_rightminus1 :: (Eq g, Cancellative g) => g -> g -> Bool
law_Cancellative_rightminus1 g1 g2 = (g1 + g2) - g2 == g1

law_Cancellative_rightminus2 :: (Eq g, Cancellative g) => g -> g -> Bool
law_Cancellative_rightminus2 g1 g2 = g1 + (g2 - g2) == g1

instance Cancellative Int        where (-) = (P.-)
instance Cancellative Integer    where (-) = (P.-)
instance Cancellative Float      where (-) = (P.-)
instance Cancellative Double     where (-) = (P.-)
instance Cancellative Rational   where (-) = (P.-)

instance Cancellative () where
    ()-() = ()

instance (Cancellative a, Cancellative b) => Cancellative (a,b) where
    (a1,b1)-(a2,b2) = (a1-a2,b1-b2)

instance (Cancellative a, Cancellative b, Cancellative c) => Cancellative (a,b,c) where
    (a1,b1,c1)-(a2,b2,c2) = (a1-a2,b1-b2,c1-c2)

instance (Cancellative a, Cancellative b, Cancellative c, Cancellative d) => Cancellative (a,b,c,d) where
    (a1,b1,c1,d1)-(a2,b2,c2,d2) = (a1-a2,b1-b2,c1-c2,d1-d2)

instance Cancellative b => Cancellative (a -> b) where
    f-g = \a -> f a - g a

-- | The GrothendieckGroup is a general way to construct groups from cancellative groups.
--
-- FIXME: How should this be related to the Ratio type?
--
-- See <http://en.wikipedia.org/wiki/Grothendieck_group wikipedia> for more details.
data GrothendieckGroup g where
    GrotheindieckGroup :: Cancellative g => g -> GrothendieckGroup g

---------------------------------------

class (Cancellative g, Monoid g) => Group g where
    {-# INLINE negate #-}
    negate :: g -> g
    negate g = zero - g

defn_Group_negateminus :: (Eq g, Group g) => g -> g -> Bool
defn_Group_negateminus g1 g2 = g1 + negate g2 == g1 - g2

law_Group_leftinverse :: (Eq g, Group g) => g -> Bool
law_Group_leftinverse g = negate g + g == zero

law_Group_rightinverse :: (Eq g, Group g) => g -> Bool
law_Group_rightinverse g = g + negate g == zero

instance Group Int        where negate = P.negate
instance Group Integer    where negate = P.negate
instance Group Float      where negate = P.negate
instance Group Double     where negate = P.negate
instance Group Rational   where negate = P.negate

instance Group () where
    negate () = ()

instance (Group a, Group b) => Group (a,b) where
    negate (a,b) = (negate a,negate b)

instance (Group a, Group b, Group c) => Group (a,b,c) where
    negate (a,b,c) = (negate a,negate b,negate c)

instance (Group a, Group b, Group c, Group d) => Group (a,b,c,d) where
    negate (a,b,c,d) = (negate a,negate b,negate c,negate d)

instance Group b => Group (a -> b) where negate f = negate . f

---------------------------------------

-- type AbelianGroup g = (Abelian g, Group g)
-- class AbelianGroup g

class Semigroup m => Abelian m

law_Abelian_commutative :: (Abelian g, Eq g) => g -> g -> Bool
law_Abelian_commutative g1 g2 = g1 + g2 == g2 + g1

instance Abelian Int
instance Abelian Integer
instance Abelian Float
instance Abelian Double
instance Abelian Rational

instance Abelian ()
instance (Abelian a, Abelian b) => Abelian (a,b)
instance (Abelian a, Abelian b, Abelian c) => Abelian (a,b,c)
instance (Abelian a, Abelian b, Abelian c, Abelian d) => Abelian (a,b,c,d)

instance Abelian b => Abelian (a -> b)

---------------------------------------

-- | FIXME: What constraint should be here? Semigroup?
--
-- See <http://ncatlab.org/nlab/show/normed%20group ncatlab>
class
    ( Ord (Scalar g)
    , HasScalar g
    ) => Normed g where
    abs :: g -> Scalar g

instance Normed Int       where abs = P.abs
instance Normed Integer   where abs = P.abs
instance Normed Float     where abs = P.abs
instance Normed Double    where abs = P.abs
instance Normed Rational  where abs = P.abs

---------------------------------------

-- | A Rg is a Ring without multiplicative identity or negative numbers.
-- (Hence the removal of the i and n from the name.)
--
-- There is no standard terminology for this structure.
-- They might also be called \"semirings without identity\", \"pre-semirings\", or \"hemirings\".
-- See <http://math.stackexchange.com/questions/359437/name-for-a-semiring-minus-multiplicative-identity-requirement this stackexchange question> for a discussion on naming.
--
class (Abelian r, Monoid r) => Rg r where
    infixl 7 *
    (*) :: r -> r -> r

law_Rg_multiplicativeAssociativity :: (Eq r, Rg r) => r -> r -> r -> Bool
law_Rg_multiplicativeAssociativity r1 r2 r3 = (r1 * r2) * r3 == r1 * (r2 * r3)

law_Rg_multiplicativeCommutivity :: (Eq r, Rg r) => r -> r -> Bool
law_Rg_multiplicativeCommutivity r1 r2 = r1*r2 == r2*r1

law_Rg_annihilation :: (Eq r, Rg r) => r -> Bool
law_Rg_annihilation r = r * zero == zero

law_Rg_distributivityLeft :: (Eq r, Rg r) => r -> r -> r -> Bool
law_Rg_distributivityLeft r1 r2 r3 = r1*(r2+r3) == r1*r2+r1*r3

theorem_Rg_distributivityRight :: (Eq r, Rg r) => r -> r -> r -> Bool
theorem_Rg_distributivityRight r1 r2 r3 = (r2+r3)*r1 == r2*r1+r3*r1

instance Rg Int         where (*) = (P.*)
instance Rg Integer     where (*) = (P.*)
instance Rg Float       where (*) = (P.*)
instance Rg Double      where (*) = (P.*)
instance Rg Rational    where (*) = (P.*)

instance Rg b => Rg (a -> b) where f*g = \a -> f a * f a

---------------------------------------

-- | A Rig is a Rg with multiplicative identity.
-- They are also known as semirings.
--
-- See <https://en.wikipedia.org/wiki/Semiring wikipedia>
-- and <http://ncatlab.org/nlab/show/rig ncatlab>
-- for more details.
class (Monoid r, Rg r) => Rig r where
    -- | the multiplicative identity
    one :: r

law_Rig_multiplicativeId :: (Eq r, Rig r) => r -> Bool
law_Rig_multiplicativeId r = r * one == r && one * r == r

instance Rig Int         where one = 1
instance Rig Integer     where one = 1
instance Rig Float       where one = 1
instance Rig Double      where one = 1
instance Rig Rational    where one = 1

instance Rig b => Rig (a -> b) where one = \a -> one

---------------------------------------

-- | FIXME: made into a class due to TH limitations
-- > type Rng r = (Rg r, Group r)
class (Rg r, Group r) => Rng r
instance (Rg r, Group r) => Rng r

-- |
--
-- It is not part of the standard definition of rings that they have a "fromInteger" function.
-- It follows from the definition, however, that we can construct such a function.
-- The "slowFromInteger" function is this standard construction.
--
-- See <https://en.wikipedia.org/wiki/Ring_%28mathematics%29 wikipedia>
-- and <http://ncatlab.org/nlab/show/ring ncatlab>
-- for more details.
class (Rng r, Rig r) => Ring r where
    fromInteger :: Integer -> r
    fromInteger = slowFromInteger

defn_Ring_fromInteger :: (Eq r, Ring r) => r -> Integer -> Bool
defn_Ring_fromInteger r i = fromInteger i `asTypeOf` r
                         == slowFromInteger i

-- | Here we construct an element of the Ring based on the additive and multiplicative identities.
-- This function takes O(n) time, where n is the size of the Integer.
-- Most types should be able to compute this value significantly faster.
--
-- FIXME: replace this with peasant multiplication.
slowFromInteger :: forall r. (Rng r, Rig r) => Integer -> r
slowFromInteger i = if i>0
    then          foldl' (+) zero $ P.map (const (one::r)) [1..        i]
    else negate $ foldl' (+) zero $ P.map (const (one::r)) [1.. negate i]

instance Ring Int         where fromInteger = P.fromInteger
instance Ring Integer     where fromInteger = P.fromInteger
instance Ring Float       where fromInteger = P.fromInteger
instance Ring Double      where fromInteger = P.fromInteger
instance Ring Rational    where fromInteger = P.fromInteger

instance Ring b => Ring (a -> b) where fromInteger i = \_ -> fromInteger i

---------------------------------------

-- | 'Integral' numbers can be formed from a wide class of things that behave
-- like integers, but intuitively look nothing like integers.
--
-- FIXME: All Fields are integral domains; should we make it a subclass?  This wouuld have the (minor?) problem of making the Integral class have to be an approximate embedding.
-- FIXME: Not all integral domains are homomorphic to the integers (e.g. a field)
--
-- See wikipedia on <https://en.wikipedia.org/wiki/Integral_element integral elements>,
--  <https://en.wikipedia.org/wiki/Integral_domain integral domains>,
-- and the <https://en.wikipedia.org/wiki/Ring_of_integers ring of integers>.
class Ring a => Integral a where
    toInteger :: a -> Integer

    infixl 7  `quot`, `rem`

    -- | truncates towards zero
    quot :: a -> a -> a
    quot a1 a2 = fst (quotRem a1 a2)

    rem :: a -> a -> a
    rem a1 a2 = snd (quotRem a1 a2)

    quotRem :: a -> a -> (a,a)


    infixl 7 `div`, `mod`

    -- | truncates towards negative infinity
    div :: a -> a -> a
    div a1 a2 = fst (divMod a1 a2)

    mod :: a -> a -> a
    mod a1 a2 = snd (divMod a1 a2)

    divMod :: a -> a -> (a,a)


law_Integral_divMod :: (Eq a, Integral a) => a -> a -> Bool
law_Integral_divMod a1 a2 = if a2 /= 0
    then a2 * (a1 `div` a2) + (a1 `mod` a2) == a1
    else True

law_Integral_quotRem :: (Eq a, Integral a) => a -> a -> Bool
law_Integral_quotRem a1 a2 = if a2 /= 0
    then a2 * (a1 `quot` a2) + (a1 `rem` a2) == a1
    else True

law_Integral_toFromInverse :: (Eq a, Integral a) => a -> Bool
law_Integral_toFromInverse a = fromInteger (toInteger a) == a

{-# NOINLINE [1] fromIntegral #-}
fromIntegral :: (Integral a, Ring b) => a -> b
fromIntegral = fromInteger . toInteger

{-# RULES
"fromIntegral/Int->Int" fromIntegral = id :: Int -> Int
    #-}

instance Integral Int where
    div = P.div
    mod = P.mod
    divMod = P.divMod
    quot = P.quot
    rem = P.rem
    quotRem = P.quotRem
    toInteger = P.toInteger

instance Integral Integer where
    div = P.div
    mod = P.mod
    divMod = P.divMod
    quot = P.quot
    rem = P.rem
    quotRem = P.quotRem
    toInteger = P.toInteger

---------------------------------------

-- | Fields are Rings with a multiplicative inverse.
--
-- See <https://en.wikipedia.org/wiki/Field_%28mathematics%29 wikipedia>
-- and <http://ncatlab.org/nlab/show/field ncatlab>
-- for more details.
class Ring r => Field r where
    {-# INLINE reciprocal #-}
    reciprocal :: r -> r
    reciprocal r = one/r

    {-# INLINE (/) #-}
    infixl 7 /
    (/) :: r -> r -> r
    n/d = n * reciprocal d

    {-# INLINE fromRational #-}
    fromRational :: Rational -> r
    fromRational r = fromInteger (numerator r) / fromInteger (denominator r)

instance Field Float      where (/) = (P./)
instance Field Double     where (/) = (P./)
instance Field Rational   where (/) = (P./)

instance Field b => Field (a -> b) where reciprocal f = reciprocal . f

---------------------------------------

-- | The prototypical example of a bounded field is the extended real numbers.
-- Other examples are the extended hyperreal numbers and the extended rationals.
-- Each of these fields has been extensively studied, but I don't know of any studies of this particular abstraction of these fields.
--
-- See <https://en.wikipedia.org/wiki/Extended_real_number_line wikipedia> for more details.
class (Field r, Bounded r) => BoundedField r where
    nan :: r
    nan = 0/0

    isNaN :: r -> Bool

infinity :: BoundedField r => r
infinity = maxBound

negInfinity :: BoundedField r => r
negInfinity = minBound

instance BoundedField Float  where isNaN = P.isNaN
instance BoundedField Double where isNaN = P.isNaN

---------------------------------------

-- | A 'QuotientField' is a field with an 'IntegralDomain' as a subring.
-- There may be many such subrings (for example, every field has itself as an integral domain subring).
-- This is especially true in Haskell because we have different data types that represent essentially the same ring (e.g. "Int" and "Integer").
-- Therefore this is a multiparameter type class.
-- The 'r' parameter represents the quotient field, and the 's' parameter represents the subring.
-- The main purpose of this class is to provide functions that map elements in 'r' to elements in 's' in various ways.
--
-- FIXME: Need examples.  Is there a better representation?
--
-- See <http://en.wikipedia.org/wiki/Field_of_fractions wikipedia> for more details.
--
class (Ring r, Integral s) => QuotientField r s where
    truncate    :: r -> s
    round       :: r -> s
    ceiling     :: r -> s
    floor       :: r -> s

    (^^)        :: r -> s -> r

#define mkQuotientField(r,s) \
instance QuotientField r s where \
    truncate = P.truncate; \
    round    = P.round; \
    ceiling  = P.ceiling; \
    floor    = P.floor; \
    (^^)     = (P.^^)

mkQuotientField(Float,Int)
mkQuotientField(Float,Integer)
mkQuotientField(Double,Int)
mkQuotientField(Double,Integer)
mkQuotientField(Rational,Int)
mkQuotientField(Rational,Integer)

---------------------------------------

-- | FIXME: add rest of Floating functions
--
-- FIXME: There are better characterizations of many of these functions than floating.
class Field r => Floating r where
    pi :: r
    exp :: r -> r
    sqrt :: r -> r
    log :: r -> r
    (**) :: r -> r -> r
    infixl 8 **

instance Floating Float where
    pi = P.pi
    sqrt = P.sqrt
    log = P.log
    exp = P.exp
    (**) = (P.**)

instance Floating Double where
    pi = P.pi
    sqrt = P.sqrt
    log = P.log
    exp = P.exp
    (**) = (P.**)

---------------------------------------

type family Scalar m

-- FIXME: made into classes due to TH limitations
-- > type IsScalar r = (Ring r, Scalar r ~ r)
class (Ring r, Scalar r~r) => IsScalar r
instance (Ring r, Scalar r~r) => IsScalar r

-- FIXME: made into classes due to TH limitations
-- > type HasScalar a = IsScalar (Scalar a)
class IsScalar (Scalar a) => HasScalar a
instance IsScalar (Scalar a) => HasScalar a

type instance Scalar Int      = Int
type instance Scalar Integer  = Integer
type instance Scalar Float    = Float
type instance Scalar Double   = Double
type instance Scalar Rational = Rational

type instance Scalar (a,b) = Scalar a
type instance Scalar (a,b,c) = Scalar a
type instance Scalar (a,b,c,d) = Scalar a

type instance Scalar (a -> b) = Scalar b

---------------------------------------

-- | A Cone is an \"almost linear\" subspace of a module.
-- Examples include the cone of positive real numbers and the cone of positive semidefinite matrices.
--
-- See <http://en.wikipedia.org/wiki/Cone_%28linear_algebra%29 wikipedia for more details.
--
-- FIXME:
-- There are many possible laws for cones (as seen in the wikipedia article).
-- I need to explicitly formulate them here.
-- Intuitively, the laws should apply the module operations and then project back into the "closest point" in the cone.
--
-- FIXME:
-- We're using the definition of a cone from linear algebra.
-- This definition is closely related to the definition from topology.
-- What is needed to ensure our definition generalizes to topological cones?
-- See <http://en.wikipedia.org/wiki/Cone_(topology) wikipedia>
-- and <http://ncatlab.org/nlab/show/cone ncatlab> for more details.
class (Cancellative m, HasScalar m, Rig (Scalar m)) => Cone m where
    infixl 7 *..
    (*..) :: Scalar m -> m -> m

    infixl 7 ..*..
    (..*..) :: m -> m -> m

---------------------------------------

class (Abelian m, Group m, HasScalar m, Ring (Scalar m)) => Module m where
    infixl 7 *.
    (*.) :: Scalar m -> m -> m

    infixl 7 .*.
    (.*.) :: m -> m -> m

{-# INLINE (.*) #-}
infixl 7 .*
(.*) :: Module m => m -> Scalar m -> m
m .* r  = r *. m

instance (Module a, Module b, Scalar a ~ Scalar b) => Module (a,b) where
    r *. (a,b) = (r*.a, r*.b)
    (a1,b1).*.(a2,b2) = (a1.*.a2,b1.*.b2)

instance (Module a, Module b, Module c, Scalar a ~ Scalar b, Scalar a ~ Scalar c) => Module (a,b,c) where
    r *. (a,b,c) = (r*.a, r*.b,r*.c)
    (a1,b1,c1).*.(a2,b2,c2) = (a1.*.a2,b1.*.b2,c1.*.c2)

instance
    ( Module a, Module b, Module c, Module d
    , Scalar a ~ Scalar b, Scalar a ~ Scalar c, Scalar a~Scalar d
    ) => Module (a,b,c,d)
        where
    r *. (a,b,c,d) = (r*.a, r*.b,r*.c,r*.d)
    (a1,b1,c1,d1).*.(a2,b2,c2,d2) = (a1.*.a2,b1.*.b2,c1.*.c2,d1.*.d2)

instance Module Int       where (*.) = (*); (.*.) = (*)
instance Module Integer   where (*.) = (*); (.*.) = (*)
instance Module Float     where (*.) = (*); (.*.) = (*)
instance Module Double    where (*.) = (*); (.*.) = (*)
instance Module Rational  where (*.) = (*); (.*.) = (*)

instance Module      b => Module      (a -> b) where
    b  *. f = \a -> b    *. f a
    g .*. f = \a -> g a .*. f a

---------------------------------------

class (Module v, Field (Scalar v)) => VectorSpace v where
    {-# INLINE (./) #-}
    infixl 7 ./
    (./) :: v -> Scalar v -> v
    v ./ r = v .* reciprocal r

    infixl 7 ./.
    (./.) :: v -> v -> v

instance (VectorSpace a,VectorSpace b, Scalar a ~ Scalar b) => VectorSpace (a,b) where
    (a,b) ./ r = (a./r,b./r)
    (a1,b1)./.(a2,b2) = (a1./.a2,b1./.b2)

instance (VectorSpace a, VectorSpace b, VectorSpace c, Scalar a ~ Scalar b, Scalar a ~ Scalar c) => VectorSpace (a,b,c) where
    (a,b,c) ./ r = (a./r,b./r,c./r)
    (a1,b1,c1)./.(a2,b2,c2) = (a1./.a2,b1./.b2,c1./.c2)

instance
    ( VectorSpace a, VectorSpace b, VectorSpace c, VectorSpace d
    , Scalar a ~ Scalar b, Scalar a ~ Scalar c, Scalar a~Scalar d
    ) => VectorSpace (a,b,c,d)
        where
    (a,b,c,d)./r = (a./r, b./r,c./r,d./r)
    (a1,b1,c1,d1)./.(a2,b2,c2,d2) = (a1./.a2,b1./.b2,c1./.c2,d1./.d2)

instance VectorSpace Float     where (./) = (/); (./.) = (/)
instance VectorSpace Double    where (./) = (/); (./.) = (/)
instance VectorSpace Rational  where (./) = (/); (./.) = (/)

instance VectorSpace b => VectorSpace (a -> b) where g ./. f = \a -> g a ./. f a

---------------------------------------

-- |
--
-- Note: It is not axiomatic that an inner product space's field must be non-finite (and hence normed and ordered).
-- However, it necessarily follows from the axioms.
-- Therefore, we include these class constraints.
-- In practice, this greatly simplifies many type signatures.
-- See this <http://math.stackexchange.com/questions/49348/inner-product-spaces-over-finite-fields stackoverflow question> for a detailed explanation of these constraints.
--
-- Note: Similarly, it is not axiomatic that every 'InnerProductSpace' is a 'MetricSpace'.
-- This is easy to see, however, since the "innerProductNorm" function can be used to define a metric on any inner product space.
-- The implementation will probably not be efficient, however.
--
-- Note: Machine learning papers often talk about Hilbert spaces, which are a minor extension of inner product spaces.
-- Specifically, the metric space must be complete.
-- I know of no useful complete metric spaces that can be represented in finite space on a computer, however, so we use the more general inner product spaces in this library.
class
    ( VectorSpace v
    , MetricSpace v
    , HasScalar v
    , Normed (Scalar v)
    , Floating (Scalar v)
    ) => InnerProductSpace v
        where

    infix 8 <>
    (<>) :: v -> v -> Scalar v

{-# INLINE squaredInnerProductNorm #-}
squaredInnerProductNorm :: InnerProductSpace v => v -> Scalar v
squaredInnerProductNorm v = v<>v

{-# INLINE innerProductNorm #-}
innerProductNorm :: (Floating (Scalar v), InnerProductSpace v) => v -> Scalar v
innerProductNorm = sqrt . squaredInnerProductNorm

{-# INLINE innerProductDistance #-}
innerProductDistance :: (Floating (Scalar v), InnerProductSpace v) => v -> v -> Scalar v
innerProductDistance v1 v2 = innerProductNorm $ v1-v2

---------------------------------------

-- | FIXME: This needs to relate to a Monoidal category
class
    ( VectorSpace v
    , Scalar (Outer v) ~ Scalar v
    , Ring (Outer v)
    ) => OuterProductSpace v
        where
    type Outer v
    infix 8 ><
    (><) :: v -> v -> Outer v

---------------------------------------

class
--     ( Field (Scalar v)
    ( Ord (Scalar v)
    , Ring (Scalar v)
    , Eq v
    ) => MetricSpace v
        where

    distance :: v -> v -> Scalar v

    {-# INLINE isFartherThan #-}
    isFartherThan :: v -> v -> Scalar v -> Bool
    isFartherThan s1 s2 b = {-# SCC isFartherThan #-} if dist > b
        then True
        else False
            where
                dist = distance s1 s2

--     {-# INLINE isFartherThanWithDistance #-}
--     isFartherThanWithDistance :: v -> v -> Scalar v -> Strict.Maybe (Scalar v)
--     isFartherThanWithDistance s1 s2 b = if dist > b
--         then Strict.Nothing
--         else Strict.Just $ dist
--         where
--             dist = distance s1 s2

    {-# INLINE isFartherThanWithDistanceCanError #-}
    isFartherThanWithDistanceCanError :: CanError (Scalar v) => v -> v -> Scalar v -> Scalar v
    isFartherThanWithDistanceCanError s1 s2 b = {-# SCC isFartherThanWithDistanceCanError  #-} if dist > b
        then errorVal
        else dist
        where
            dist = distance s1 s2

law_MetricSpace_nonnegativity :: MetricSpace v => v -> v -> Bool
law_MetricSpace_nonnegativity v1 v2 = distance v1 v2 >= 0

law_MetricSpace_indiscernables :: (Eq v, MetricSpace v) => v -> v -> Bool
law_MetricSpace_indiscernables v1 v2 = if v1 == v2
    then distance v1 v2 == 0
    else distance v1 v2 > 0

law_MetricSpace_symmetry :: MetricSpace v => v -> v -> Bool
law_MetricSpace_symmetry v1 v2 = distance v1 v2 == distance v2 v1

law_MetricSpace_triangle :: MetricSpace v => v -> v -> v -> Bool
law_MetricSpace_triangle m1 m2 m3
    = distance m1 m2 <= distance m1 m3 + distance m2 m3
   && distance m1 m3 <= distance m1 m2 + distance m2 m3
   && distance m2 m3 <= distance m1 m3 + distance m2 m1

instance MetricSpace Int      where distance x1 x2 = abs $ x1 - x2
instance MetricSpace Integer  where distance x1 x2 = abs $ x1 - x2
instance MetricSpace Float    where distance x1 x2 = abs $ x1 - x2
instance MetricSpace Double   where distance x1 x2 = abs $ x1 - x2
instance MetricSpace Rational where distance x1 x2 = abs $ x1 - x2

---------

data Maybe' a
    = Nothing'
    | Just' !a

instance NFData a => NFData (Maybe' a) where
    rnf Nothing' = ()
    rnf (Just' a) = rnf a

class CanError a where
    errorVal :: a
    isError :: a -> Bool

    isJust :: a -> Bool
    isJust = not isError

instance CanError (Maybe a) where
    {-# INLINE isError #-}
    isError Nothing = True
    isError _ = False

    {-# INLINE errorVal #-}
    errorVal = Nothing

instance CanError (Maybe' a) where
    {-# INLINE isError #-}
    isError Nothing' = True
    isError _ = False

    {-# INLINE errorVal #-}
    errorVal = Nothing'

instance CanError Float where
    {-# INLINE isError #-}
    {-# INLINE errorVal #-}
    isError = isNaN
    errorVal = 0/0

instance CanError Double where
    {-# INLINE isError #-}
    {-# INLINE errorVal #-}
    isError = isNaN
    errorVal = 0/0

-------------------------------------------------------------------------------
-- set-like

class (Monoid s, POrd s, Container s, MinBound s, Unfoldable s, Foldable s) => FreeMonoid s
instance (Monoid s, POrd s, Container s, MinBound s, Unfoldable s, Foldable s) => FreeMonoid s

-- class (Set s, Cat (+>)) => EndoFunctor s (+>) where
--     efmap :: (a +> b) -> s { Elem :: a } +> s { Elem :: b }
--     efmap :: (a +> b) -> s a +> s b
--
-- class (Unfoldable s, EndoFunctor s (+>)) => Applicative s (+>) where
--     (<*>) :: s { Elem :: (a +> b) } -> s { Elem :: a } +> s { Elem :: b }
--     (<*>) :: s (a +> b) -> s a +> s b
--
-- class (Unfoldable s, EndoFunctor s (+>)) => Monad s (+>) where
--     join :: ValidCategory (+>) a => s (s a) +> s a

type Item s = Elem s

class Monoid s => Container s where
    type Elem s :: *
--     type ElemConstraint s :: Constraint
--     type ElemConstraint s = ()
    elem :: {-ElemConstraint s =>-} Elem s -> s -> Bool

law_Container_preservation :: (Container s) => s -> s -> Elem s -> Bool
law_Container_preservation s1 s2 e = if e `elem` s1 || e `elem` s2
    then e `elem` (s1+s2)
    else True

law_Container_empty :: (Container s) => s -> Elem s -> Bool
law_Container_empty s e = elem e (empty `asTypeOf` s) == False

-- | a slightly more suggestive name for a container's monoid identity
empty :: (Monoid s{-, Container s-}) => s
empty = zero

-- |
--
-- prop> isOpen empty == True
--
-- prop> isOpen a && isOpen b   ===>   isOpen (a || b)
--
-- prop> isOpen a && isOpen b   ===>   isOpen (a && b)
--
-- prop> closed
--
class (Boolean s, Container s) => Topology s where
    isOpen   :: s -> Bool
    isClosed :: s -> Bool

    isClopen :: s -> Bool
    isClopen s = isOpen && isClosed $ s

    isNeighborhood :: Elem s -> s -> Bool

-- |
--
-- TODO: How is this related to Constuctable sets?
-- https://en.wikipedia.org/wiki/Constructible_set_%28topology%29
class (Normed s, Monoid s) => Unfoldable s where
    -- | creates the smallest container with the given element
    --
    -- > elem x (singleton x) == True
    --
    -- but it is not necessarily the case that
    --
    -- > x /= y   ===>   elem y (singleton x) == False
    --
    -- TODO: should we add this restriction?
    singleton :: Elem s -> s

    -- | FIXME: if -XOverloadedLists is enabled, this causes an infinite loop for some reason
    fromList :: [Elem s] -> s
    fromList xs = foldr cons zero xs

    fromListN :: Int -> [Elem s] -> s
    fromListN _ = fromList

    -- | inserts an element on the left
    cons :: Elem s -> s -> s
    cons x xs = singleton x + xs

    -- | inserts an element on the right
    snoc :: s -> Elem s -> s
    snoc xs x = xs + singleton x

law_Unfoldable_cons :: (Container s, Unfoldable s) => s -> Elem s -> Bool
law_Unfoldable_cons s e = elem e (cons e s) == True

law_Unfoldable_snoc :: (Container s, Unfoldable s) => s -> Elem s -> Bool
law_Unfoldable_snoc s e = elem e (snoc s e) == True

-- | This function needed for the OverloadedStrings language extension
fromString :: (Unfoldable s, Elem s ~ Char) => String -> s
fromString = fromList

-- | For an Abelian Container, cons==snoc
insert :: (Unfoldable s, Abelian s) => Elem s -> s -> s
insert = cons

-- | Provides inverse operations for "Unfoldable".
--
class Monoid s => Foldable s where

    {-# INLINE toList #-}
    toList :: Foldable s => s -> [Elem s]
    toList s = foldr (:) [] s

    -- |
    --
    -- > unCons zero == Nothing
    --
    -- > unCons (cons x xs) = Just (x, xs)
    --
    unCons :: s -> Maybe (Elem s,s)

    -- |
    --
    -- > unSnoc zero == Nothing
    --
    -- > unSnoc (snoc xs x) = Just (xs, x)
    --
    unSnoc :: s -> Maybe (s,Elem s)

    -- |
    --
    -- prop> isEmpty x == (abs x == 0)
    isEmpty :: s -> Bool
    isEmpty s = case unCons s of
        Nothing -> True
        otherwise -> False

    foldMap :: Monoid a => (Elem s -> a) -> s -> a
    foldr   :: (Elem s -> a -> a) -> a -> s -> a
    foldr'  :: (Elem s -> a -> a) -> a -> s -> a
    foldr1  :: (Elem s -> Elem s -> Elem s) -> s -> Elem s
    foldr1' :: (Elem s -> Elem s -> Elem s) -> s -> Elem s
    foldl   :: (a -> Elem s -> a) -> a -> s -> a
    foldl'  :: (a -> Elem s -> a) -> a -> s -> a
    foldl1  :: (Elem s -> Elem s -> Elem s) -> s -> Elem s
    foldl1' :: (Elem s -> Elem s -> Elem s) -> s -> Elem s

    -- | the default summation uses kahan summation
    sum :: (Abelian (Elem s), Group (Elem s)) => s -> Elem s
    sum = snd . foldl' go (zero,zero)
        where
            go (c,t) i = ((t'-t)-y,t')
                where
                    y = i-c
                    t' = t+y

{-# INLINE reduce #-}
reduce :: (Monoid (Elem s), Foldable s) => s -> Elem s
reduce s = foldl' (+) zero s

-- | For anything foldable, the norm must be compatible with the folding structure.
{-# INLINE length #-}
length :: Unfoldable s => s -> Scalar s
length = abs

-- FIXME: this is really slow; does it have a space leak? or is it just cache misses?
foldtList :: forall a. Monoid a => (a -> a -> a) -> a -> [a] -> a
foldtList f x0 xs = case go xs of
    [] -> x0
    (x:xs) -> f x0 x
    where
        go :: [a] -> [a]
        go [] = []
        go (x:[]) = [x]
        go (x1:x2:xs) = go $ f x1 x2 : go xs

{-# INLINE concat #-}
concat :: (Monoid (Elem s), Foldable s) => s -> Elem s
concat = foldl' (+) zero

{-# INLINE headMaybe #-}
headMaybe :: Foldable s => s -> Maybe (Elem s)
headMaybe = P.fmap fst . unCons

{-# INLINE tailMaybe #-}
tailMaybe :: Foldable s => s -> Maybe s
tailMaybe = P.fmap snd . unCons

{-# INLINE lastMaybe #-}
lastMaybe :: Foldable s => s -> Maybe (Elem s)
lastMaybe = P.fmap snd . unSnoc

{-# INLINE initMaybe #-}
initMaybe :: Foldable s => s -> Maybe s
initMaybe = P.fmap fst . unSnoc

class {-Container s =>-} Indexed s where
    type Index s :: *
    type Index s = Int

    (!) :: s -> Index s -> Elem s
    (!) s i = case s !! i of
        Just x -> x
        Nothing -> error "used (!) on an invalid index"

    (!!) :: s -> Index s -> Maybe (Elem s)

    findWithDefault :: Elem s -> Index s -> s -> Elem s
    findWithDefault def i s = case s !! i of
        Nothing -> def
        Just e -> e

    hasIndex :: Index s -> s -> Bool
    hasIndex i s = case s !! i of
        Nothing -> False
        Just _ -> True

class (Monoid s, {-Container s, -}Indexed s) => IndexedUnfoldable s where
    singletonAt :: Index s -> Elem s -> s

    consAt :: Index s -> Elem s -> s -> s
    consAt i e s = singletonAt i e + s

    snocAt :: s -> Index s -> Elem s -> s
    snocAt s i e = s + singletonAt i e

    fromIndexedList :: [(Index s, Elem s)] -> s
    fromIndexedList = foldl' (\s (i,e) -> snocAt s i e) empty

class (IndexedUnfoldable s) => IndexedFoldable s where
    toIndexedList :: s -> [(Index s, Elem s)]

    elems :: s -> [Elem s]
    elems = map snd . toIndexedList

    keys :: s -> [Index s]
    keys = map fst . toIndexedList

insertAt :: (IndexedUnfoldable s, Abelian s) => Index s -> Elem s -> s -> s
insertAt = consAt

class (IndexedFoldable s) => IndexedDeletable s where
    deleteAt :: Index s -> s -> s

-- type Topology s = (Boolean s, Set s)
-- type Measurable s = (Topology s, Normed s)
--
-- class Set s => MultiSet s where
--     numElem :: Elem s -> s -> Scalar s

-------------------

newtype Lexical a = Lexical a
    deriving (Read,Show,Arbitrary,NFData,Semigroup,Monoid)

type instance Scalar (Lexical a) = Scalar a

instance Container a => Container (Lexical a) where
    type Elem (Lexical a) = Elem a
--     type ElemConstraint (Lexical a) = ElemConstraint a
    elem e (Lexical a) = elem e a

deriving instance Normed a => Normed (Lexical a)
deriving instance (Eq (Elem a), Foldable a, MetricSpace a) => MetricSpace (Lexical a)
deriving instance Unfoldable a => Unfoldable (Lexical a)
deriving instance Foldable a => Foldable (Lexical a)

instance (Eq (Elem a), Foldable a) => Eq (Lexical a) where
    (Lexical a1)==(Lexical a2) = toList a1==toList a2

instance (Ord (Elem a), Foldable a) => InfSemilattice (Lexical a) where
    inf a1 a2 = if a1 < a2 then a1 else a2

instance (Ord (Elem a), Foldable a) => SupSemilattice (Lexical a) where
    sup a1 a2 = if a1 > a2 then a1 else a2

instance (Ord (Elem a), Foldable a) => Lattice (Lexical a) where

instance (Ord (Elem a), Foldable a) => MinBound (Lexical a) where
    minBound = Lexical zero

instance (Ord (Elem a), Foldable a) => POrd (Lexical a) where
    pcompare (Lexical a1) (Lexical a2) = go (toList a1) (toList a2)
        where
            go [] [] = PEQ
            go [] _  = PLT
            go _  [] = PGT
            go (a1:as1) (a2:as2) = case pcompare a1 a2 of
                PLT -> PLT
                PGT -> PGT
                PNA -> PNA
                PEQ -> go as1 as2

instance (Ord (Elem a), Foldable a) => Ord (Lexical a)

-------------------

type instance Scalar [a] = Int

instance POrd a => InfSemilattice [a] where
    inf [] _  = []
    inf _  [] = []
    inf (x:xs) (y:ys) = if x==y
        then x:inf xs ys
        else []

instance POrd a => POrd [a] where
    pcompare [] [] = PEQ
    pcompare [] _  = PLT
    pcompare _  [] = PGT
    pcompare (x:xs) (y:ys) = case (pcompare x y, pcompare xs ys) of
        (PEQ,PLT) -> PLT
        (PEQ,PGT) -> PGT
        (PEQ,PEQ) -> PEQ
        _         -> PNA

instance Normed [a] where
    abs = P.length

instance Semigroup [a] where
    (+) = (P.++)

instance Monoid [a] where
    zero = []

instance Eq a => Container [a] where
    type Elem [a] = a
--     type ElemConstraint [a] = Eq a
    elem _ []       = False
    elem x (y:ys)   = x==y || elem x ys

instance Unfoldable [a] where
    singleton a = [a]
    cons x xs = x:xs

instance Foldable [a] where
    unCons [] = Nothing
    unCons (x:xs) = Just (x,xs)

    unSnoc [] = Nothing
    unSnoc xs = Just (P.init xs,P.last xs)

    foldMap f s = concat $ P.map f s

    foldr = L.foldr
    foldr' = L.foldr
    foldr1 = L.foldr1
    foldr1' = L.foldr1

    foldl = L.foldl
    foldl' = L.foldl'
    foldl1 = L.foldl1
    foldl1' = L.foldl1'

instance Indexed [a] where
    (!!) [] _ = Nothing
    (!!) (x:xs) 0 = Just x
    (!!) (x:xs) i = xs !! (i-1)

-------------------------------------------------------------------------------
-- compatibility layer types

newtype IndexedVector k v = IndexedVector { unsafeGetMap :: Map.Map (WithPreludeOrd k) v }
    deriving (Read,Show,NFData)

type instance Scalar (IndexedVector k v) = Scalar v

-- | This is the L2 norm of the vector.
instance (Floating (Scalar v), IsScalar v, Ord v) => Normed (IndexedVector k v) where
    {-# INLINE abs #-}
    abs (IndexedVector m) =
        {-# SCC abs_IndexedVector #-}
        sqrt $ sum $ map (**2) $ Map.elems m

instance (Floating (Scalar v), IsScalar v, Ord v, Ord k) => MetricSpace (IndexedVector k v) where
    {-# INLINE distance #-}
    distance (IndexedVector m1) (IndexedVector m2) =
        {-# SCC distance_IndexedVector #-}
        sqrt $ go 0 (Map.assocs m1) (Map.assocs m2)
        where
            go tot [] [] = tot
            go tot [] ((k,v):xs) = go (tot+v*v) [] xs
            go tot ((k,v):xs) [] = go (tot+v*v) [] xs

            go tot ((k1,v1):xs1) ((k2,v2):xs2) = case compare k1 k2 of
                EQ -> go (tot+(v1-v2)*(v1-v2)) xs1 xs2
                LT -> go (tot+v1*v1) xs1 ((k2,v2):xs2)
                GT -> go (tot+v2*v2) ((k1,v1):xs1) xs1

    isFartherThanWithDistanceCanError (IndexedVector m1) (IndexedVector m2) dist =
        {-# SCC isFartherThanWithDistanceCanError_IndexedVector #-}
        sqrt $ go 0 (Map.assocs m1) (Map.assocs m2)
        where
            dist2 = dist*dist

            go tot [] [] = tot
            go tot xs ys = if tot > dist2
                then errorVal
                else go' tot xs ys

            go' tot [] ((k,v):xs) = go (tot+v*v) [] xs
            go' tot ((k,v):xs) [] = go (tot+v*v) [] xs

            go' tot ((k1,v1):xs1) ((k2,v2):xs2) = case compare k1 k2 of
                EQ -> go (tot+(v1-v2)*(v1-v2)) xs1 xs2
                LT -> go (tot+v1*v1) xs1 ((k2,v2):xs2)
                GT -> go (tot+v2*v2) ((k1,v1):xs1) xs1

instance (Eq k, Eq v) => Eq (IndexedVector k v) where
    (IndexedVector m1)==(IndexedVector m2) = m1' == m2'
        where
            m1' = removeWithPreludeOrd $ Map.toList m1
            m2' = removeWithPreludeOrd $ Map.toList m2
            removeWithPreludeOrd [] = []
            removeWithPreludeOrd ((WithPreludeOrd k,v):xs) = (k,v):removeWithPreludeOrd xs

-- FIXME: this would be faster if we don't repeat all the work of the comparisons
-- FIXME: is this the correct instance?
-- FIXME: this is the ordering for an Array; create a SparseArray type
-- instance (Ord k, Eq v, Semigroup v) => POrd (IndexedVector k v) where
--     pcompare (IndexedVector m1) (IndexedVector m2) = if (IndexedVector m1)==(IndexedVector m2)
--         then PEQ
--         else if Map.isSubmapOfBy (==) m1 m2
--             then PLT
--             else if Map.isSubmapOfBy (==) m2 m1
--                 then PGT
--                 else PNA

instance (Ord k, POrd v, Semigroup v) => POrd (IndexedVector k v) where
    pcompare (IndexedVector m1) (IndexedVector m2) = go (Map.assocs m1) (Map.assocs m2)
        where
            go [] [] = PEQ
            go [] _  = PLT
            go _  [] = PGT
            go ((k1,v1):xs1) ((k2,v2):xs2) = case pcompare k1 k2 of
                PNA -> PNA
                PLT -> PLT
                PGT -> PGT
                PEQ -> case pcompare v1 v2 of
                    PNA -> PNA
                    PLT -> PLT
                    PGT -> PGT
                    PEQ -> go xs1 xs2

instance (Ord k, POrd v, Semigroup v) => Ord (IndexedVector k v) where

instance (Ord k, Semigroup v) => InfSemilattice (IndexedVector k v) where
    inf (IndexedVector m1) (IndexedVector m2) = IndexedVector $ Map.unionWith (+) m1 m2

instance (Ord k, Semigroup v) => SupSemilattice (IndexedVector k v) where
    sup (IndexedVector m1) (IndexedVector m2) = IndexedVector $ Map.intersectionWith (+) m1 m2

instance (Ord k, Semigroup v) => Lattice (IndexedVector k v) where

instance (Ord k, Semigroup v) => Semigroup (IndexedVector k v) where
    (+) = inf

instance (Ord k, Semigroup v) => Monoid (IndexedVector k v) where
    zero = IndexedVector $ Map.empty

instance (Ord k, Abelian v) => Abelian (IndexedVector k v)

instance (Ord k, Semigroup v, Eq v) => Container (IndexedVector k v) where
    type Elem (IndexedVector k v) = v
--     type ElemConstraint (IndexedVector k v) = Eq v
    elem x (IndexedVector m) = elem x $ P.map snd $ Map.toList m

instance (Ord k, Semigroup v) => Indexed (IndexedVector k v) where
    type Index (IndexedVector k v) = k
    (IndexedVector m) !! k = Map.lookup (WithPreludeOrd k) m

instance (Ord k, Semigroup v) => IndexedUnfoldable (IndexedVector k v) where
    singletonAt i e = IndexedVector $ Map.singleton (WithPreludeOrd i) e

    consAt i e (IndexedVector s) = IndexedVector $ Map.insert (WithPreludeOrd i) e s

    snocAt (IndexedVector s) i e = IndexedVector $ Map.insert (WithPreludeOrd i) e s

    fromIndexedList xs = IndexedVector $ Map.fromList $ map (\(i,e) -> (WithPreludeOrd i,e)) xs

instance (Ord k, Semigroup v) => IndexedFoldable (IndexedVector k v) where
    toIndexedList (IndexedVector s) = map (\(WithPreludeOrd i,e) -> (i,e)) $ Map.assocs s

instance (Ord k, Semigroup v) => IndexedDeletable (IndexedVector k v) where
    deleteAt k (IndexedVector s) = IndexedVector $ Map.delete (WithPreludeOrd k) s

---------------------------------------

newtype Set a = Set (Set.Set (WithPreludeOrd a))

type instance Scalar (Set a) = Int

instance Normed (Set a) where
    abs (Set s) = Set.size s

instance Eq a => Eq (Set a) where
    (Set s1)==(Set s2) = s1'==s2'
        where
            s1' = removeWithPreludeOrd $ Set.toList s1
            s2' = removeWithPreludeOrd $ Set.toList s2
            removeWithPreludeOrd [] = []
            removeWithPreludeOrd (WithPreludeOrd x:xs) = x:removeWithPreludeOrd xs

-- | FIXME: this would be faster if we don't repeat all the work of the comparisons
instance Ord a => POrd (Set a) where
    pcompare (Set s1) (Set s2) = if (Set s1)==(Set s2)
        then PEQ
        else if Set.isSubsetOf s1 s2
            then PLT
            else if Set.isSubsetOf s2 s1
                then PGT
                else PNA

instance Ord a => InfSemilattice (Set a) where
    inf (Set s1) (Set s2) = Set $ Set.union s1 s2

instance Ord a => SupSemilattice (Set a) where
    sup (Set s1) (Set s2) = Set $ Set.intersection s1 s2

instance Ord a => Lattice (Set a) where

instance Ord a => MinBound (Set a) where
    minBound = Set $ Set.empty

instance Ord a => Semigroup (Set a) where
    (Set s1)+(Set s2) = Set $ Set.union s1 s2

instance Ord a => Monoid (Set a) where
    zero = Set $ Set.empty

instance Ord a => Abelian (Set a)

instance Ord a => Container (Set a) where
    type Elem (Set a) = a
    elem a (Set s) = Set.member (WithPreludeOrd a)s

instance Ord a => Unfoldable (Set a) where
    singleton a = Set $ Set.singleton (WithPreludeOrd a)
