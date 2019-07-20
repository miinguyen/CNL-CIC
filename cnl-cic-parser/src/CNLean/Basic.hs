{-
Author(s): Jesse Michael Han (2019)

Basic parser combinators.
-}

{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}
module CNLean.Basic where

import Prelude
import qualified Prelude
import Text.Megaparsec
import Text.Megaparsec.Char
import Data.Text (Text, pack, unpack, toLower)
import Data.Void
import qualified Data.Char as C
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void Text

repeatN :: Int -> Parser a -> Parser a
repeatN n p = foldr (>>) p $ replicate (n-1) p

infixl 3 <||>
(<||>) :: Parser a -> Parser a -> Parser a
p <||> q = (try p) <|> q


(<+>) :: Parser Text -> Parser Text -> Parser Text
p <+> q = do
  a <- p
  b <- q
  return $ a <> b

join :: [Text] -> Text
join ts = foldl (<>) "" ts

sc :: Parser ()
sc = L.space
  space1 -- note, space1 uses spaceChar so consumes newlines, tabs, etc also
  (L.skipLineComment "%")
  (L.skipBlockComment "%%%" "%%%")

symbol :: Text -> Parser Text
symbol arg = L.symbol sc arg

many1 :: Parser a -> Parser [a]
many1 p = do
  x <- p
  xs <- many p
  return (x:xs)

symbol' :: Text -> Parser Text
symbol' arg = L.symbol' sc arg

not_space_aux :: Parser Char
not_space_aux = (satisfy (\x -> x /= ' '))

not_space :: Parser Text
not_space = (many1 not_space_aux) >>= return . pack

succeeds :: Parser a -> Parser Bool
succeeds p = (p >> return True) <|> return False

item :: Parser Char
item = satisfy (\_ -> True)

not_whitespace_aux :: Parser Char
not_whitespace_aux = do
  b <- succeeds $ lookAhead spaceChar
  if b then fail "whitespace character ahead, failing"
       else item

fold :: [Parser a] -> Parser a
fold ps = foldr (<||>) empty ps

not_whitespace :: Parser Text
not_whitespace = (many1 not_whitespace_aux) >>= return . pack

word :: Parser Text
word = not_whitespace <* sc

digit :: Parser Text
digit = digitChar >>= return . pack . pure

number :: Parser Text
number = (many1 digit) >>= return . join

alpha :: Parser Text
alpha = (upperChar <||> lowerChar) >>= return . pack . pure

alphanum :: Parser Text
alphanum = (many1 (alpha <||> digit)) >>= return . join

ch :: Char -> Parser Text
ch c = Text.Megaparsec.Char.char c >>= return . pack . pure

str :: Text -> Parser Text
str t = do
  Text.Megaparsec.Char.string t

str' :: Text -> Parser Text
str' t = do
  Text.Megaparsec.Char.string' t

str_eq' :: Text -> Text -> Prelude.Bool
str_eq' t1 t2 = (toLower t1) == (toLower t2)

---- backtracking version of many, used to implement backtracking versions of sepby and sepby1
many' :: Parser a -> Parser [a]
many' p = (do
  a <- p
  as <- many' p
  return (a:as) ) <||> return []

---- backtracking version of many1. fails unless if p succeeds at least once
many1' :: Parser a -> Parser [a]
many1' p = do
  a  <- p
  as <- (many' p)
  return $ a : as

sepby_aux :: Parser a -> Parser b -> Parser [a]
sepby_aux p sep =
  (:) <$> p <*> (many' (sep *> p))  

sepby :: Parser a -> Parser b -> Parser [a]
sepby p sep = (sepby_aux p sep) <||> return []

fail_if_empty :: (Eq a) => Parser [a] -> Parser [a]
fail_if_empty p = do
  x <- p
  if x == [] then fail "is empty list" else return x

sepby1 :: (Eq a) => Parser a -> Parser b -> Parser [a]
sepby1 p sep = fail_if_empty $ sepby p sep

---- lookAhead' strictly looks ahead, returning no values upon success
lookAhead' :: Parser a -> Parser ()
lookAhead' p = (lookAhead p >> return ()) <||> fail "lookahead failed"

-- sepBy' :: Parser a -> Parser b -> Parser [a]
-- sepBy' p sep = do
--   x <- try p
--   xs <- try (sepBy' sep *> p)
--   return $ x:xs
  
  
  
