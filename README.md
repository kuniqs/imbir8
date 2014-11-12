imbir8
======

Imbir Component System in Lua


 w = World()
   i = Imbir{x=2,c='i'}
   s = System{
      'x','c',
      Logic = function(i)
         print(i.x,i.c)
      end}
   w = w + Imbir{x=1,c='a'} + Imbir{x=3,c='b'} + s + i -- add 3 imbirs and subscribe 1 system to world w
   w = w - i
   Iterate{s,s} -> will print
      '1   a'
      '3   b'
      '1   a'
      '3   b'
