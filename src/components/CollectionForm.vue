<template>
  <div class="max-w-2xl mx-auto bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
    <div class="flex justify-between items-center mb-6 border-b border-gray-100 pb-3">
      <h2 class="text-2xl font-bold text-gray-800">
        {{ isEditMode ? 'Editar Colección' : 'Nueva Colección' }}
      </h2>
      <button @click="$emit('cancel')" class="text-xs font-bold text-gray-500 hover:text-gray-700">
        ✕ Cancelar
      </button>
    </div>

    <div v-if="loadingData" class="text-center py-8 text-gray-500">
      Cargando datos de la colección...
    </div>

    <form v-else @submit.prevent="saveCollection" class="space-y-6">
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
            <option value="Papa">Papa</option>
            <option value="Mama">Mama</option>
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
          <input v-model.number="collection.total_regular" type="number" min="1" required
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
            <input v-model.number="group.total" type="number" min="1" required
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
      <div class="pt-4 flex gap-3">
        <button type="button" @click="$emit('cancel')"
          class="w-1/3 bg-gray-100 text-gray-700 font-bold py-3 rounded-lg hover:bg-gray-200 transition">
          Cancelar
        </button>
        <button type="submit" :disabled="isSubmitting"
          class="w-2/3 bg-blue-600 text-white font-bold py-3 rounded-lg shadow hover:bg-blue-700 transition disabled:opacity-50">
          {{ isSubmitting ? 'Guardando...' : (isEditMode ? 'Guardar Cambios' : 'Crear Colección') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../supabase'

const props = defineProps({
  collectionId: {
    type: String,
    default: null
  }
})

const emit = defineEmits(['saved', 'cancel'])

const isEditMode = computed(() => !!props.collectionId)
const isSubmitting = ref(false)
const loadingData = ref(false)

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

// Cargar datos si estamos en modo edición
const loadExistingData = async () => {
  if (!props.collectionId) return
  loadingData.value = true
  try {
    const { data: col, error: colErr } = await supabase
      .from('collections')
      .select('*')
      .eq('id', props.collectionId)
      .single()
    if (colErr) throw colErr
    collection.value = col

    const { data: groups, error: sgErr } = await supabase
      .from('special_groups')
      .select('prefix, total')
      .eq('collection_id', props.collectionId)
    if (sgErr) throw sgErr
    specialGroups.value = groups || []
  } catch (err) {
    console.error('Error cargando colección para editar:', err)
  } finally {
    loadingData.value = false
  }
}

const saveCollection = async () => {
  isSubmitting.value = true

  try {
    let currentId = props.collectionId

    if (isEditMode.value) {
      // 1. UPDATE colección existente
      const { error: colErr } = await supabase
        .from('collections')
        .update({
          title: collection.value.title,
          description: collection.value.description,
          image_url: collection.value.image_url,
          owner: collection.value.owner,
          total_regular: collection.value.total_regular
        })
        .eq('id', currentId)

      if (colErr) throw colErr

      // Reemplazar grupos especiales (borrar anteriores e insertar nuevos)
      await supabase.from('special_groups').delete().eq('collection_id', currentId)
      if (specialGroups.value.length > 0) {
        const groupsToInsert = specialGroups.value.map(g => ({
          collection_id: currentId,
          prefix: g.prefix,
          total: g.total
        }))
        await supabase.from('special_groups').insert(groupsToInsert)
      }

    } else {
      // 2. INSERT nueva colección
      const { data: colData, error: colErr } = await supabase
        .from('collections')
        .insert([collection.value])
        .select()

      if (colErr) throw colErr
      currentId = colData[0].id

      if (specialGroups.value.length > 0) {
        const groupsToInsert = specialGroups.value.map(g => ({
          collection_id: currentId,
          prefix: g.prefix,
          total: g.total
        }))
        await supabase.from('special_groups').insert(groupsToInsert)
      }

      await supabase.from('progress').insert([{ collection_id: currentId, acquired: [] }])
    }

    emit('saved', currentId)

  } catch (error) {
    console.error('Error al guardar:', error)
    alert('Hubo un error al guardar los datos.')
  } finally {
    isSubmitting.value = false
  }
}

onMounted(loadExistingData)
</script>