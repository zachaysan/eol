
# IDEAL SYNTAX

a = 3

b = a + c

c = 5

puts b

eoeol

d = sum([1,2,3])

e = [1,2,3,4,5]

f = (e) + c

g = (e,f) # => 1, 7, 3, 9, 5

puts (g)

IDEAL "pre-machine-code"

(= a 3 )

(+ b a)

(= c 5)

(= d (sum 1 2 3))

(= f (+ (shift e) b))


(= g (shift e f))
(= g (shift e (+ (shift e) c)))
(= g (shift e (+ (shift e) 5)))

reserved words
eoeol: when used on its own stops the parser
