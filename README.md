# Sistema de Conciliación - Desafío Técnico

## 📋 Descripción del Proyecto

Este proyecto es una base para implementar un sistema de **conciliación de transacciones** entre tiendas, clientes y billeteras. El desarrollador debe implementar el proceso de conciliación que permita reconciliar movimientos y detectar inconsistencias, además de crear un **portal web para comercios** donde puedan acceder a sus datos, realizar conciliaciones y descargar reportes.

## 🏗️ Estructura del Sistema

### Modelos Principales

- **Store (Tienda)**: Representa los comercios que reciben pagos
- **Customer (Cliente)**: Representa los usuarios que realizan pagos
- **Wallet (Billetera)**: Billeteras virtuales para tiendas y clientes
- **Transaction (Transacción)**: Movimientos de dinero entre billeteras
- **Sale (Venta)**: Ventas realizadas por las tiendas

### Funcionalidades Base Implementadas

✅ **CRUD completo** para tiendas, clientes y transacciones  
✅ **Billeteras** con balances automáticos  
✅ **Validaciones** de datos y reglas de negocio  
✅ **Datos de prueba** realistas y correlacionados  
✅ **Métodos de consulta** para conciliación  
✅ **Rutas y controladores** básicos  
✅ **Modelo Sale** para ventas de tiendas  
✅ **Datos correlacionados** entre ventas y transacciones  

## 🎯 Desafío: Implementar el Proceso de Conciliación

### Objetivo Principal
El desarrollador debe implementar un **sistema de conciliación** y un **portal para comercios** que permita:

1. **Reconciliar transacciones** entre diferentes fuentes de datos
2. **Detectar inconsistencias** en balances y movimientos
3. **Generar reportes** de conciliación
4. **Identificar transacciones duplicadas** o faltantes
5. **Proporcionar acceso web** a los comercios para gestionar sus datos
6. **Permitir descarga de reportes** en formatos PDF y Excel

### Funcionalidades a Implementar

#### 1. Proceso de Conciliación
- [ ] **Conciliación automática** basada en monto, fecha y referencia
- [ ] **Conciliación manual** para casos especiales
- [ ] **Reglas de matching** configurables
- [ ] **Tolerancia de fechas** para conciliación

#### 2. Detección de Inconsistencias
- [ ] **Verificación de balances** vs transacciones
- [ ] **Detección de transacciones duplicadas**
- [ ] **Identificación de transacciones faltantes**
- [ ] **Alertas de inconsistencias**

#### 3. Reportes de Conciliación
- [ ] **Reporte de conciliación diaria**
- [ ] **Reporte de inconsistencias**
- [ ] **Dashboard de conciliación**
- [ ] **Exportación de reportes**

#### 4. Portal para Comercios
- [ ] **Dashboard del comercio** con resumen de ventas y transacciones
- [ ] **Vista de conciliación** con transacciones emparejadas
- [ ] **Filtros avanzados** por fecha, cliente, estado
- [ ] **Acciones masivas** para conciliación
- [ ] **Historial de conciliaciones**
- [ ] **Reportes descargables** en PDF/Excel
- [ ] **Notificaciones** de inconsistencias detectadas

## 🚀 Instalación y Configuración

### Prerrequisitos
- Ruby 3.2+
- Rails 8.0+
- SQLite3

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd challenge
```

2. **Instalar dependencias**
```bash
bundle install
```

3. **Configurar base de datos**
```bash
rails db:create
rails db:migrate
```

4. **Cargar datos de prueba**
```bash
rails db:seed
```

5. **Iniciar el servidor**
```bash
rails server
```

6. **Acceder a la aplicación**
```
http://localhost:3000
```

## 📊 Datos de Prueba Disponibles

El sistema incluye datos de prueba realistas y correlacionados:

- **5 Tiendas** con diferentes tipos de negocio
- **8 Clientes** con datos completos
- **13 Billeteras** (5 de tiendas + 8 de clientes)
- **~20+ Ventas** correlacionadas con transacciones
- **~50+ Transacciones** de diferentes tipos:
  - Pagos de clientes a tiendas (correlacionados con ventas)
  - Reembolsos parciales
  - Transacciones pendientes y fallidas
- **Archivo CSV** de transferencias diarias para conciliación

## 🔧 Estructura de Datos

### Transacciones Disponibles
- **payment**: Pagos de clientes a tiendas
- **refund**: Reembolsos de tiendas a clientes
- **deposit**: Depósitos iniciales a billeteras
- **fee**: Comisiones y cargos

### Estados de Ventas
- **completed**: Venta completada
- **pending**: Venta pendiente
- **cancelled**: Venta cancelada
- **refunded**: Venta reembolsada

### Estados de Transacciones
- **completed**: Transacción exitosa
- **pending**: Transacción pendiente
- **failed**: Transacción fallida

### Tipos de Billeteras
- **store**: Billeteras de tiendas
- **customer**: Billeteras de clientes

## 🎯 Criterios de Evaluación

### Funcionalidad (40%)
- Implementación correcta del proceso de conciliación
- Detección precisa de inconsistencias
- Generación de reportes útiles

### Código (30%)
- Código limpio y bien estructurado
- Uso de patrones de diseño apropiados
- Manejo adecuado de errores

### Portal para Comercios (20%)
- Portal intuitivo y fácil de usar para comercios
- Dashboard con métricas relevantes
- Filtros y búsquedas efectivas
- Visualización clara de datos de conciliación
- Reportes descargables y funcionales

### Documentación (10%)
- README actualizado
- Comentarios en el código
- Documentación de API si aplica

## 💡 Sugerencias de Implementación

### Enfoque Recomendado
1. **Analizar los datos existentes** para entender patrones
2. **Usar el archivo CSV** de transferencias diarias como fuente externa
3. **Definir reglas de conciliación** claras
4. **Implementar matching automático** entre ventas y transacciones
5. **Conciliar con transferencias** del archivo CSV
6. **Crear el portal para comercios** con dashboard y reportes
7. **Agregar funcionalidades manuales** después
8. **Implementar notificaciones** y alertas

### Consideraciones Técnicas
- Usar **transacciones de base de datos** para consistencia (puedes crear más datos si es necesario)
- Implementar **background jobs** para procesos pesados
- Usar **validaciones** para prevenir inconsistencias

### Herramientas Útiles
- **Sidekiq** para jobs en background
- **Chartkick** para gráficos y dashboards
- **Device** para el manejo de las sesiones

## 📝 Notas Importantes

- **Crear un portal específico** para que los comercios puedan acceder a sus datos
- **Implementar autenticación** para que cada comercio vea solo sus datos
- **Mantener** las validaciones y relaciones existentes
- **Usar** los métodos ya implementados cuando sea posible
- **Documentar** cualquier cambio significativo

## 🆘 Soporte

Para dudas sobre la implementación, revisar:
- Los métodos ya implementados en los modelos
- Los datos de prueba en `db/seeds.rb`
- Las rutas disponibles en `config/routes.rb`
- El archivo `transferencias_diarias.csv` para conciliación

¡Buena suerte con el desafío! 🚀
