#Introducir dos números enteros y visualizar primero el menor y después el mayor.
n1 = int (input("Dame un numero que sea entero "))
n2 = int (input("Dame otro numero que sea entero "))
if n1 < n2:
    print (f"EL numero menor es {n1}")
    print (f"El numero mayor es {n2}")
else:
    print (f"El numeor menor es {n2}")
    print (f"El numero mayor es {n1}")
