#Introducir dos números enteros y visualizar si el primer número es divisible o no por el segundo número.
n1=int (input("Dame el primer numero entero "))
n2=int (input("Dame el segundo numero entero "))
if n1 % n2 == 0:
    print("El numero es divisible")
else:
    print ("El numeor no es divisible")
