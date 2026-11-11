<template>
  <div class="max-w-2xl mx-auto bg-white p-8 rounded-xl shadow-lg border-2 border-gray-100">
    <h2 class="text-2xl font-bold text-gray-800 mb-6 border-b-2 border-blue-500 pb-2">
      Nueva Colección
    </h2>

    <form @submit.prevent="saveCollection" class="space-y-6">
      <!-- Datos básicos -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="col-span-1 md:col-span-2">
          <label class="block text-sm font-semibold text-gray-700 mb-1">Título de la colección</label>
          <input v-model="collection.title" type="text" required
            class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-400 outline-none"
            placeholder="Ej: La Liga 2026-27" />
        </div>

        <div class="col-span-1 md:col-span-2">
          <label class="block text-sm font-semibold text-gray-700 mb-1">Descripción</label>
          <textarea v-model="collection.description" rows="2"
            class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-400 outline-none"
            placeholder="Opcional..."></textarea>
        </div>

        <div class="col-span-1">
          <label class="block text-sm font-semibold text-gray-700 mb-1">Propietario</label>
          <select v-model="collection.owner" required
            class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-400 outline-none bg-white">
            <option value="Papá">Papa</option>
            <option value="Mamá">Mama</option>
            <option value="Nara">Nara</option>
            <option value="Familiar">Familiar (Compartida)</option>
          </select>
        </div>

        <div class="col-span-1">
          <label class="block text-sm font-semibold text-gray-700 mb-1">URL de la Portada</label>
          <input v-model="collection.image_url" type="url"
            class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-400 outline-none"
            placeholder="https://..." />
        </div>

        <div class="col-span-1 md:col-span-2 mt-4">
          <label class="block text-sm font-semibold text-gray-700 mb-1">Total de cromos normales (Numéricos)</label>
          <input v-model="collection.total_regular" type="number" min="1" required
            class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-400 outline-none" />
        </div>
      </div>

      <!-- Grupos Especiales -->
      <div class="mt-8 bg-gray-50 p-4 rounded-lg border border-gray-200">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-sm font-bold text-gray-700">Grupos Especiales (Ej: X1 a X20)</h3>
          <button type="button" @click="addSpecialGroup"
            class="text-xs bg-blue-100 text-blue-700 px-3 py-1 rounded-md font-bold hover:bg-blue-200 transition">
            + Añadir Grupo
          </button>
        </div>

        <div v-for="(group, index) in specialGroups" :key="index" class="flex gap-3 mb-3 items-end">
          <div class="flex-1">
            <label class="block text-xs text-gray-600 mb-1">Prefijo (Ej: X)</label>
            <input v-model="group.prefix" type="text" required
              class="w-full px-3 py-1.5 border rounded focus:ring-2 focus:ring-blue-400 outline-none" />
          </div>
          <div class="flex-1">
            <label class="block text-xs text-gray-600 mb-1">Cantidad</label>
            <input v-model="group.total" type="number" min="1" required
              class="w-full px-3 py-1.5 border rounded focus:ring-2 focus:ring-blue-400 outline-none" />
          </div>
          <button type="button" @click="removeSpecialGroup(index)"
            class="text-red-500 hover:text-red-700 px-2 py-1.5 mb-0.5">
            ✕
          </button>
        </div>
        <p v-if="specialGroups.length === 0" class="text-xs text-gray-500 italic">
          Sin cromos especiales.
        </p>
      </div>

      <!-- Submit -->
      <div class="pt-4">
        <button type="submit" :disabled="isSubmitting"
          class="w-full bg-blue-600 text-white font-bold py-3 rounded-lg shadow hover:bg-blue-700 transition disabled:opacity-50">
          {{ isSubmitting ? 'Guardando...' : 'Crear Colección' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { supabase } from '../supabase' // Ajusta la ruta si es necesario

const isSubmitting = ref(false)

const collection = ref({
  title: '',
  description: '',
  image_url: '',
  owner: 'Nara',
  total_regular: 100
})

const specialGroups = ref([])

const addSpecialGroup = () => {
  specialGroups.value.push({ prefix: '', total: 10 })
}

const removeSpecialGroup = (index) => {
  specialGroups.value.splice(index, 1)
}

const saveCollection = async () => {
  isSubmitting.value = true

  try {
    // 1. Insertar Colección principal
    const { data: colData, error: colError } = await supabase
      .from('collections')
      .insert([collection.value])
      .select()

    if (colError) throw colError
    const newCollectionId = colData[0].id

    // 2. Insertar Grupos Especiales (si los hay)
    if (specialGroups.value.length > 0) {
      const groupsToInsert = specialGroups.value.map(g => ({
        collection_id: newCollectionId,
        prefix: g.prefix,
        total: g.total
      }))
      
      const { error: sgError } = await supabase
        .from('special_groups')
        .insert(groupsToInsert)
        
      if (sgError) throw sgError
    }

    // 3. Inicializar el Progreso vacío
    const { error: progError } = await supabase
      .from('progress')
      .insert([{ 
        collection_id: newCollectionId, 
        acquired: [] 
      }])

    if (progError) throw progError

    alert('¡Colección guardada con éxito!')
    
    // Resetear formulario
    collection.value = { title: '', description: '', image_url: '', owner: 'Nara', total_regular: 100 }
    specialGroups.value = []

  } catch (error) {
    console.error('Error guardando la colección:', error)
    alert('Hubo un error al guardar. Revisa la consola.')
  } finally {
    isSubmitting.value = false
  }
}
</script>