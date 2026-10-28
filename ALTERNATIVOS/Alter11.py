# Crea un programa-calculadora con un menú de opciones que dé a elegir entre suma, resta, multiplicación,
# división o resto entre dos números enteros.

n1 = int(input("Dame un numero entero: "))
n2 = int(input("Dame segundo numero entero: "))

print("Opciones: + (suma), - (resta), * (multiplicacion), / (division), % (resto)")
opcion = input("Dame una opcion: ")

if opcion == "+":
    operacion1 = n1 + n2
    print("La suma daria", operacion1)
elif opcion == "-":
    operacion2 = n1 - n2
    print("La resta seria", operacion2)
elif opcion == "*":
    operacion3 = n1 * n2
    print("La multiplicacion seria", operacion3)
elif opcion == "/":
    if n2 != 0:
        operacion4 = n1 / n2
        print("La division daria", operacion4)
    else:
        print("No se puede dividir entre cero")
elif opcion == "%":
    if n2 != 0:
        operacion5 = n1 % n2
        print("El resto seria", operacion5)
    else:
        print("No se puede calcular el resto entre cero")
else:
    print("La operacion no es posible ejecutarse")