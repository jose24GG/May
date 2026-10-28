import math
catetoA = float(input("Dame el primer cateto: "))
catetoB = float(input("Dame el segundo cateto: "))
hipotenusa = math.sqrt(catetoA**2 + catetoB**2)
print(f"La hipotenusa del triángulo rectángulo es {hipotenusa}")
