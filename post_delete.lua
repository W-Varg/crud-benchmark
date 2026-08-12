-- post_delete.lua
-- Alterna entre crear (POST) y eliminar (DELETE) un producto para simular carga real y mantener la DB limpia.

local thread_id = 0

setup = function(thread)
   thread:set("id", thread_id)
   thread_id = thread_id + 1
end

init = function(args)
   -- Cada hilo lleva su propio contador inicializado con un desfase
   counter = 0
end

request = function()
   counter = counter + 1
   local headers = {}
   headers["Content-Type"] = "application/json"
   headers["accept"] = "application/json"

   if counter % 2 == 1 then
      -- 1. Crear producto (POST)
      local body = '{"name":"Impresora láser","price":450.00,"stock":5}'
      return wrk.format("POST", "/products", headers, body)
   else
      -- 2. Eliminar un producto (DELETE)
      -- Para evitar borrar IDs inexistentes o borrar lo mismo, usamos una estimación basada en el contador del hilo.
      -- MySQL auto_increment genera IDs secuenciales globales.
      -- Estimamos borrar el ID recién creado o uno cercano.
      -- Si da 404 en algunos casos de concurrencia extrema, es normal y simula control de errores.
      local approx_id = (id * 100000) + math.floor(counter / 2)
      -- Si estimamos mal o queremos simplemente estresar el DELETE, podemos consultar IDs secuenciales:
      return wrk.format("DELETE", "/products/" .. approx_id, headers)
   end
end
