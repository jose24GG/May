#Introducir los tres valores para una ecuación de segundo grado (a, b, c). Visualizar el resultado solo si sus raíces 
# son reales (cuando al realizar el cálculo de dentro de la raíz nos da >=0).
valora = int(input("Introduce el valor de a: "))
valorb = int(input("Introduce el valor de b: "))
valorc = int(input("Introduce el valor de c: "))

operacion = (valorb ** 2) - (4 * valora * valorc)

if operacion >= 0:
    x1 = (-valorb + (operacion ** 0.5)) / (2 * valora)
    x2 = (-valorb - (operacion ** 0.5)) / (2 * valora)
    print("Las raíces son reales")
    print("x1 =", x1)
    print("x2 =", x2)
else:
    print("Las raíces no son reales")