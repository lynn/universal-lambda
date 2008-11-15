import System
import Char
import IO

data T = Var Int 
       | Lam T
       | App T T
         deriving (Show)
data V = Fun (V -> V)
       | Val Int
       | Str String

app :: V -> V -> V
app (Fun f) v = f v

eval :: T -> [V] -> V
eval (Var x) e = e !! x
eval (Lam t) e = Fun (\v -> eval t (v:e))
eval (App a b) e = eval a e `app` eval b e

unchurch :: V -> Int
unchurch c = i where 
	Val i = c `app` Fun inc `app` Val 0 
	inc (Val x) = Val (x+1)
church i = Fun (\f -> Fun (\x -> iterate (app f) x !! i))

-- \l . l (\a b i.unchurch a : unlist b) ""
unlist :: V -> String
unlist l = s where Str s = unlist' l
unlist' :: V -> V
unlist' l = l `app` Fun walk `app` Str "" where
	walk a = Fun (\b -> Fun (\i-> Str (chr (unchurch a) : unlist b)))

cons a b = Fun (\x -> x `app` a `app` b)
nil = Fun (\a -> Fun (\b -> b) )
tolist "" = nil
tolist (x:xs) = cons (church (ord x)) (tolist xs)

type BitStream = ([Int], String)
stepBit :: BitStream -> (Int, BitStream)
stepBit (x:xs, ys) = (x, (xs, ys))
stepBit ([], y:ys) = ((ord y) `div` 128, (map (\p->(ord y) `div` 2^p `mod` 2) [6,5..0], ys))

parse :: BitStream -> (T, BitStream)
parse s =
	if a == 1 then
		getVar s2 0
	else
		if b == 0 then
			(Lam e1, r1)
		else
			(App e1 e2, r2)
	where
		(a,s2) = stepBit s
		(b,s3) = stepBit s2
		(e1,r1) = parse(s3)
		(e2,r2) = parse(r1)
		getVar s i = 
			if a==1 then
				getVar s2 (i+1)
			else
				(Var i, s2)
			where (a,s2) = stepBit s
	
main=do
	sources <- mapM readFile =<< getArgs
	hSetBuffering stdout NoBuffering
	interact (\input->
		let
			(tree, (_, rest)) = parse stream
			stream = ([], concat sources ++ input)
		in unlist (eval tree [] `app` tolist rest))
