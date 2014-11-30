{-# LANGUAGE NoAutoDeriveTypeable #-} -- can't derive typeable of data families

module SubHask.SubType
    where

import Control.Monad
import Language.Haskell.TH
import Language.Haskell.TH.Quote
import Language.Haskell.Meta

import SubHask.Internal.Prelude
import Prelude (($),id,Eq (..))

import Debug.Trace

-------------------------------------------------------------------------------

-- | Subtypes are partially ordered.
-- Unfortunately, there's no way to use the machinery of the "POrd"/"Lattice" classes.
-- The "Sup" type family is a promotion of the "sup" function to the type level.
--
-- It must obey the laws:
--
-- > Sup a b c   <===>   ( a <: c, b <: c )
--
-- > Sub a b c   <===>   Sup b a c
--
-- And there is no smaller value of "c" that can be used instead.
--
-- FIXME: it would be nicer if this were a type family; is that possible?
class Sup (s::k) (t::k) (u::k) | s t -> u

instance Sup s s s

-- | We use `s <: t` to denote that s is s subtype of t.
-- The "embedType" function must be s homomorphism from s to t.
--
class (Sup s t t, Sup t s t) => (s :: k) <: (t :: k) where
    embedType_ :: Embed s t -- a b


-- | This data type is a huge hack to work around some unimplemented features in the type system.
-- In particular, we want to be able to declare any type constructor to be a subtype of any other type constructor.
-- The main use case is for making subcategories use the same subtyping mechanism as other types.
--
-- FIXME: replace this data family with a system based on type families;
-- everything I've tried so far requires injective types or foralls in constraints.
data family Embed (s::k) (t::k) -- (a::ka) (b::kb)

newtype instance Embed (s :: *) (t :: *)
    = Embed0 { unEmbed0 :: s -> t }
embedType :: (s <: t) => s -> t
embedType = unEmbed0 embedType_
instance (a :: *) <: (a :: *) where
    embedType_ = Embed0 $ id

newtype instance Embed (s :: ka -> *) (t :: ka -> *)
    = Embed1 { unEmbed1 :: forall a. s a -> t a }
embedType1 :: (s <: t) => s a -> t a
embedType1 = unEmbed1 embedType_
instance (a :: k1 -> *) <: (a :: k1 -> *) where
    embedType_ = Embed1 $ id

newtype instance Embed (s :: ka -> kb -> *) (t :: ka -> kb -> *)
    = Embed2 { unEmbed2 :: forall a b. s a b -> t a b}
embedType2 :: forall s t a b. (s <: t) => s a b -> t a b
embedType2 = case embedType_ :: Embed s t of
    Embed2 f -> f
instance (a :: k1 -> k2 -> *) <: (a :: k1 -> k2 -> *) where
    embedType_ = Embed2 $ id


-- | FIXME: can these laws be simplified at all?
-- In particular, can we automatically infer ctx from just the function parameter?
law_Subtype_f1 ::
    ( a <: b
    , Eq b
    , ctx a
    , ctx b
    ) => proxy ctx  -- ^ this parameter is only for type inference
      -> b          -- ^ this parameter is only for type inference
      -> (forall c. ctx c => c -> c)
      -> a
      -> Bool
law_Subtype_f1 _ b f a = embedType (f a) == f (embedType a) `asTypeOf` b

law_Subtype_f2 ::
    ( a <: b
    , Eq b
    , ctx a
    , ctx b
    ) => proxy ctx  -- ^ this parameter is only for type inference
      -> b          -- ^ this parameter is only for type inference
      -> (forall c. ctx c => c -> c -> c)
      -> a
      -> a
      -> Bool
law_Subtype_f2 _ b f a1 a2 = embedType (f a1 a2) == f (embedType a1) (embedType a2) `asTypeOf` b

-------------------

type family a == b :: Bool where
    a == a = True
    a == b = False

type family If (a::Bool) (b::k) (c::k) :: k where
    If True  b c = b
    If False b c = c

type family When (a::Bool) (b::Constraint) :: Constraint where
    When True  b = b
    When False b = ()

-------------------

instance Sup Double Int Double
instance Sup Int Double Double

apEmbedType1 ::
    ( a1 <: b1
    ) => (b1 -> c) -> a1 -> c
apEmbedType1 f a = f (embedType a)

apEmbedType2 ::
    ( a1 <: b1
    , a2 <: b2
    , When (b1==b2) (Sup a1 a2 b1)
    ) => (b1 -> b2 -> c)
      -> (a1 -> a2 -> c)
apEmbedType2 f a b = f (embedType a) (embedType b)

--------------------------------------------------------------------------------
-- template haskell
-- FIXME: move this into the template haskell folder?

-- |
--
-- FIXME: This should automatically search for other subtypes that can be inferred from t1 and t2
--
mkSubtype :: Q Type -> Q Type -> Name -> Q [Dec]
mkSubtype qt1 qt2 f = do
    t1 <- liftM stripForall qt1
    t2 <- liftM stripForall qt2
    return $ mkSubtypeInstance t1 t2 f:mkSup t1 t2 t2

-- | converts types created by `[t| ... |]` into a more useful form
stripForall :: Type -> Type
stripForall (ForallT _ _ t) = stripForall t
stripForall (VarT t) = VarT $ mkName $ nameBase t
stripForall (ConT t) = ConT t
stripForall (AppT t1 t2) = AppT (stripForall t1) (stripForall t2)

-- | Calling:
--
-- > mkSubtypeInstance a b f
--
-- generates the following code:
--
-- > instance a <: b where
-- >    embedType_ = Embed0 f
--
-- FIXME: What if the type doesn't have kind *?
mkSubtypeInstance :: Type -> Type -> Name -> Dec
mkSubtypeInstance t1 t2 f = InstanceD
    []
    ( AppT
        ( AppT
            ( ConT $ mkName "<:" )
            t1
        )
        t2
    )
    [ FunD
        ( mkName "embedType_" )
        [ Clause
            []
            ( NormalB $ AppE
                ( ConE $ mkName "Embed0" )
                ( VarE f )
            )
            []
        ]
    ]

-- | Calling:
--
-- > mkSup a b c
--
-- generates the following code:
--
-- > instance Sup a b c
-- > instance Sup b a c
--
mkSup :: Type -> Type -> Type -> [Dec]
mkSup t1 t2 t3 =
    [ InstanceD [] (AppT (AppT (AppT (ConT $ mkName "Sup") t1) t2) t3) []
    , InstanceD [] (AppT (AppT (AppT (ConT $ mkName "Sup") t2) t1) t3) []
    ]

---------------------------------------
-- quasiquoting

s=subhask

-- | defines the modified syntax that simplifies use of the subhask library
subhask = QuasiQuoter
    { quoteExp = go parseExp subcatExp
    , quoteDec = go parseDecs (map subcatDec)
    }
    where
        go parse eval = \str -> case parse str of
            Left err -> error $ "parse error: "++err
            Right th -> return $ eval th

-- | This is a not-quite quasiquoter for using subtypes.
-- It requires the TemplateHaskell extension, but not the QuasiQuoter extension.
-- Use it like:
--
-- > var = $(sub_[| 1+2*4 |])
--
exp_ :: Q Exp -> Q Exp
exp_ qe = do
    e <- qe
    let ret = subcatExp e
    trace ("\nsubtype substitution\n  orig="++show e++"\n  ret="++show ret) $ return ()
    return ret

dec_ :: Q [Dec] -> Q [Dec]
dec_ qd = do
    d <- qd
    let ret = map subcatDec d
    return ret

subcatDec :: Dec -> Dec
subcatDec (SigD n t) = SigD n t
subcatDec (ValD p (NormalB e) xs) = ValD p (NormalB $ subcatExp e) $ map subcatDec xs
subcatDec x = error $ "subcatDec.undef; x="++show x

-- | This is a helper for "parseSubExp" that substitutes every function application with a call to "embedType2";
-- This lets us use objects in any subcategory of hask like normal functions.
subcatExp :: Exp -> Exp
subcatExp (InfixE (Just a1) f (Just a2)) = subcatExp $ AppE (AppE f a1) a2
subcatExp (InfixE (Just a1) f Nothing) = subcatExp $ AppE f a1
-- FIXME: the code below assumes commutativity of `f`
-- fixing this will require digging into the underlying categories
subcatExp (InfixE Nothing f (Just a2)) = subcatExp $ AppE (AppE (VarE $ mkName "flip") f) a2
subcatExp (InfixE Nothing f Nothing) = subcatExp f
subcatExp (UInfixE a1 f a2) = subcatExp $ AppE (AppE f a1) a2
subcatExp (AppE f a) = AppE (AppE (VarE $ mkName "embedType2") (subcatExp f)) (subcatExp a)
subcatExp (VarE e) = VarE e
subcatExp (ConE c) = ConE c
subcatExp (LitE l) = LitE l
subcatExp (SigE e t) = SigE (subcatExp e) t
subcatExp x = error $ "subcatExp.undef; x="++show x

-- | This is a helper for "sub" that performs the actual substitution.
--
-- FIXME: There's lots of missing cases right now!
--
subExp :: Exp -> Exp
subExp (InfixE (Just a1) f (Just a2)) = subExp $ AppE (AppE f a1) a2
subExp (UInfixE a1 f a2) = subExp $ AppE (AppE f a1) a2
subExp (AppE (AppE f a1) a2) = AppE (AppE (AppE (VarE $ mkName "apEmbedType2") f) a1) a2
-- subExp (AppE f a1) = AppE (AppE (VarE $ mkName "$") f) a1
subExp xs = xs
