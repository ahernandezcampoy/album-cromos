<template>
  <div class="min-h-screen bg-gray-100 text-gray-800">
    <!-- Navbar principal -->
    <header class="bg-white border-b border-gray-200 sticky top-0 z-50">
      <div class="max-w-6xl mx-auto px-4 py-3 flex justify-between items-center">
        <h1 class="text-xl font-bold text-blue-600 flex items-center gap-2">
          <span>📖</span> AlbumApp
        </h1>

        <div class="flex items-center gap-3">
          <select 
            v-if="collections.length > 0" 
            v-model="selectedCollectionId"
            class="px-3 py-1.5 bg-gray-50 border rounded-lg text-sm font-semibold outline-none focus:ring-2 focus:ring-blue-400"
          >
            <option v-for="col in collections" :key="col.id" :value="col.id">
              {{ col.title }} ({{ col.owner }})
            </option>
          </select>

          <button 
            @click="currentView = currentView === 'album' ? 'new' : 'album'"
            class="bg-blue-600 text-white text-xs font-bold px-3.5 py-2 rounded-lg hover:bg-blue-700 transition"
          >
            {{ currentView === 'album' ? '+ Nueva Colección' : 'Ver Álbum' }}
          </button>
        </div>
      </div>
    </header>

    <!-- Contenido Principal -->
    <main class="p-4 md:p-8">
      <div v-if="currentView === 'new'">
        <CollectionForm @created="onCollectionCreated" />
      </div>

      <div v-else-if="selectedCollectionId">
        <AlbumGrid :collectionId="selectedCollectionId" />
      </div>

      <div v-else class="text-center py-16">
        <p class="text-gray-500 mb-4">No tienes ninguna colección creada todavía.</p>
        <button 
          @click="currentView = 'new'" 
          class="bg-blue-600 text-white font-bold px-4 py-2 rounded-lg"
        >
          Crear mi primera colección
        </button>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from './supabase'
import CollectionForm from './components/CollectionForm.vue'
import AlbumGrid from './components/AlbumGrid.vue'

const currentView = ref('album')
const collections = ref([])
const selectedCollectionId = ref(null)

const fetchCollections = async () => {
  const { data, error } = await supabase
    .from('collections')
    .select('id, title, owner')
    .order('created_at', { ascending: false })

  if (!error && data && data.length > 0) {
    collections.value = data
    if (!selectedCollectionId.value) {
      selectedCollectionId.value = data[0].id
    }
  }
}

const onCollectionCreated = async () => {
  await fetchCollections()
  currentView.value = 'album'
}

onMounted(fetchCollections)
</script>