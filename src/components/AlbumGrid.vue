<template>
  <div v-if="loading" class="text-center py-12 text-gray-500 font-semibold">
    Cargando álbum...
  </div>

  <div v-else-if="!collection" class="text-center py-12 text-red-500 font-semibold">
    No se encontró la colección.
  </div>

  <div v-else class="max-w-6xl mx-auto space-y-6">
    <!-- Cabecera de la Colección -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col md:flex-row gap-6 items-center md:items-start">
      <img 
        v-if="collection.image_url" 
        :src="collection.image_url" 
        :alt="collection.title"
        class="w-32 h-44 object-cover rounded-xl shadow border border-gray-200 flex-shrink-0" 
      />
      <div v-else class="w-32 h-44 bg-gray-100 rounded-xl border-2 border-dashed border-gray-300 flex items-center justify-center text-gray-400 font-bold flex-shrink-0">
        Sin Portada
      </div>

      <div class="flex-1 text-center md:text-left space-y-2">
        <div class="flex flex-wrap items-center justify-center md:justify-start gap-2">
          <span class="bg-blue-100 text-blue-800 text-xs font-bold px-2.5 py-0.5 rounded-full">
            {{ collection.owner }}
          </span>
          <span class="bg-emerald-100 text-emerald-800 text-xs font-bold px-2.5 py-0.5 rounded-full">
            {{ progressPercentage }}% Completado
          </span>
        </div>
        <h1 class="text-3xl font-extrabold text-gray-800">{{ collection.title }}</h1>
        <p v-if="collection.description" class="text-gray-600 text-sm">{{ collection.description }}</p>

        <!-- Barra de Progreso -->
        <div class="w-full bg-gray-200 rounded-full h-3 mt-4 overflow-hidden">
          <div 
            class="bg-emerald-500 h-3 rounded-full transition-all duration-500" 
            :style="{ width: `${progressPercentage}%` }"
          ></div>
        </div>

        <div class="flex justify-between text-xs text-gray-500 pt-1 font-semibold">
          <span>Conseguidos: {{ acquiredList.length }} / {{ allStickers.length }}</span>
          <span>Faltan: {{ missingStickers.length }}</span>
        </div>
      </div>
    </div>

    <!-- Barra de Herramientas y Filtros -->
    <div class="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex flex-wrap items-center justify-between gap-4">
      <div class="flex gap-2">
        <button 
          @click="filter = 'all'" 
          :class="['px-3 py-1.5 text-xs font-bold rounded-lg transition', filter === 'all' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200']"
        >
          Todos ({{ allStickers.length }})
        </button>
        <button 
          @click="filter = 'missing'" 
          :class="['px-3 py-1.5 text-xs font-bold rounded-lg transition', filter === 'missing' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200']"
        >
          Faltan ({{ missingStickers.length }})
        </button>
        <button 
          @click="filter = 'acquired'" 
          :class="['px-3 py-1.5 text-xs font-bold rounded-lg transition', filter === 'acquired' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200']"
        >
          Tengo ({{ acquiredList.length }})
        </button>
      </div>

      <button 
        @click="copyMissingList"
        class="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold px-4 py-2 rounded-lg shadow flex items-center gap-2 transition active:scale-95"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 012-2v-8a2 2 0 01-2-2h-8a2 2 0 01-2 2v8a2 2 0 012 2z"/></svg>
        Copiar Faltas
      </button>
    </div>

    <!-- Rejilla de Cromos (Estilo Álbum) -->
    <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-10 gap-2 sm:gap-3">
      <div 
        v-for="sticker in filteredStickers" 
        :key="sticker.id"
        @click="toggleSticker(sticker.id)"
        :class="[
          'aspect-[3/4] rounded-xl flex flex-col items-center justify-center p-1 cursor-pointer select-none transition-all transform active:scale-90 border-2 font-mono font-bold text-sm sm:text-base relative overflow-hidden',
          sticker.acquired 
            ? 'bg-emerald-500 border-emerald-600 text-white shadow-md' 
            : 'bg-white border-dashed border-gray-300 text-gray-400 hover:border-blue-400 hover:text-blue-500'
        ]"
      >
        <span>{{ sticker.id }}</span>
        
        <!-- Icono Check si está conseguido -->
        <div v-if="sticker.acquired" class="absolute bottom-1 right-1">
          <svg class="w-3.5 h-3.5 text-white opacity-80" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../supabase'

const props = defineProps({
  collectionId: {
    type: String,
    required: true
  }
})

const loading = ref(true)
const collection = ref(null)
const specialGroups = ref([])
const acquiredList = ref([])
const filter = ref('all') // 'all', 'missing', 'acquired'

// Cargar datos completos de la colección desde Supabase
const loadCollectionData = async () => {
  loading.value = true
  try {
    // 1. Colección
    const { data: col, error: colErr } = await supabase
      .from('collections')
      .select('*')
      .eq('id', props.collectionId)
      .single()
    if (colErr) throw colErr
    collection.value = col

    // 2. Grupos Especiales
    const { data: groups, error: sgErr } = await supabase
      .from('special_groups')
      .select('*')
      .eq('collection_id', props.collectionId)
    if (sgErr) throw sgErr
    specialGroups.value = groups || []

    // 3. Progreso
    const { data: prog, error: progErr } = await supabase
      .from('progress')
      .select('acquired')
      .eq('collection_id', props.collectionId)
      .maybeSingle()
    if (progErr) throw progErr
    acquiredList.value = prog?.acquired || []

  } catch (err) {
    console.error('Error cargando la colección:', err)
  } finally {
    loading.value = false
  }
}

// Generar array con todos los IDs de cromos (Regular + Especiales)
const allStickers = computed(() => {
  if (!collection.value) return []
  const list = []

  // Regular (1 a N)
  for (let i = 1; i <= collection.value.total_regular; i++) {
    const idStr = String(i)
    list.push({
      id: idStr,
      acquired: acquiredList.value.includes(idStr)
    })
  }

  // Especiales (ej. X1 a X10)
  specialGroups.value.forEach(group => {
    for (let i = 1; i <= group.total; i++) {
      const idStr = `${group.prefix}${i}`
      list.push({
        id: idStr,
        acquired: acquiredList.value.includes(idStr)
      })
    }
  })

  return list
})

const missingStickers = computed(() => {
  return allStickers.value.filter(s => !s.acquired).map(s => s.id)
})

const filteredStickers = computed(() => {
  if (filter.value === 'missing') return allStickers.value.filter(s => !s.acquired)
  if (filter.value === 'acquired') return allStickers.value.filter(s => s.acquired)
  return allStickers.value
})

const progressPercentage = computed(() => {
  if (allStickers.value.length === 0) return 0
  return Math.round((acquiredList.value.length / allStickers.value.length) * 100)
})

// Marcar/Desmarcar cromo y guardar en Supabase (Optimista)
const toggleSticker = async (stickerId) => {
  const exists = acquiredList.value.includes(stickerId)
  if (exists) {
    acquiredList.value = acquiredList.value.filter(id => id !== stickerId)
  } else {
    acquiredList.value.push(stickerId)
  }

  // Persistir en Supabase
  try {
    const { error } = await supabase
      .from('progress')
      .upsert({
        collection_id: props.collectionId,
        acquired: acquiredList.value,
        updated_at: new Date().toISOString()
      })
    if (error) throw error
  } catch (err) {
    console.error('Error actualizando progreso:', err)
  }
}

// Copiar lista limpia al portapapeles
const copyMissingList = () => {
  if (missingStickers.value.length === 0) {
    alert('¡Felicidades! Ya tienes la colección completa.')
    return
  }
  const text = `Faltas de ${collection.value.title} (${missingStickers.value.length}):\n${missingStickers.value.join(', ')}`
  navigator.clipboard.writeText(text)
  alert('¡Lista de faltas copiada al portapapeles!')
}

onMounted(loadCollectionData)
watch(() => props.collectionId, loadCollectionData)
</script>