<script lang="ts">
	import { onMount } from 'svelte';
	import Dashboard from '$lib/components/Dashboard.svelte';
	import AIOrganizer from '$lib/components/AIOrganizer.svelte';
	import DiscoveryControls from '$lib/components/DiscoveryControls.svelte';
	import ResultsDisplay from '$lib/components/ResultsDisplay.svelte';
	import ActivityLog from '$lib/components/ActivityLog.svelte';
	import { homieStore } from '$lib/stores/homieStore';

	let currentView = 'dashboard'; // 'dashboard' or 'file-organizer'

	onMount(() => {
		console.log('🏠 Homie Frontend initialized');
		homieStore.addLogEntry('Frontend initialized - Ready to interact with Homie backend');

		// Simple hash-based routing
		const hash = window.location.hash.substring(1);
		if (hash === 'file-organizer') {
			currentView = 'file-organizer';
		}

		// Listen for hash changes
		window.addEventListener('hashchange', () => {
			const newHash = window.location.hash.substring(1);
			if (newHash === 'file-organizer') {
				currentView = 'file-organizer';
			} else {
				currentView = 'dashboard';
			}
		});
	});

	function goToDashboard() {
		currentView = 'dashboard';
		window.location.hash = '';
	}
</script>

<svelte:head>
	<title>🏠 Homie - Intelligent Home Management</title>
</svelte:head>

<div class="container">
	{#if currentView === 'dashboard'}
		<Dashboard />
	{:else if currentView === 'file-organizer'}
		<div class="file-organizer">
			<div class="breadcrumb">
				<button class="back-btn" on:click={goToDashboard}>
					← Back to Dashboard
				</button>
			</div>
			
			<header>
				<h1>🗂️ File Organizer</h1>
				<p>AI-powered intelligent file organization</p>
			</header>

			<main>
				<AIOrganizer />
				<ActivityLog />
			</main>
		</div>
	{/if}
</div>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
		color: #e2e8f0;
		min-height: 100vh;
		font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
	}

	.container {
		min-height: 100vh;
	}

	.file-organizer {
		max-width: 1200px;
		margin: 0 auto;
		padding: 1rem;
		min-height: 100vh;
	}

	.breadcrumb {
		margin-bottom: 2rem;
	}

	.back-btn {
		background: rgba(255, 255, 255, 0.1);
		color: #e2e8f0;
		border: 1px solid rgba(255, 255, 255, 0.2);
		padding: 0.75rem 1.5rem;
		border-radius: 10px;
		font-size: 0.875rem;
		cursor: pointer;
		transition: all 0.3s ease;
		backdrop-filter: blur(10px);
	}

	.back-btn:hover {
		background: rgba(255, 255, 255, 0.15);
		transform: translateY(-1px);
	}

	header {
		text-align: center;
		margin-bottom: 3rem;
		padding-bottom: 2rem;
		border-bottom: 2px solid rgba(255, 255, 255, 0.1);
		background: rgba(255, 255, 255, 0.02);
		border-radius: 16px;
		padding: 2rem;
		backdrop-filter: blur(10px);
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
	}

	header h1 {
		color: #ffffff;
		margin: 0 0 0.5rem 0;
		font-size: 2.5rem;
		font-weight: 700;
		background: linear-gradient(135deg, #60a5fa, #a78bfa, #f472b6);
		background-clip: text;
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		text-shadow: 0 0 30px rgba(96, 165, 250, 0.3);
	}

	header p {
		color: #94a3b8;
		margin: 0;
		font-size: 1.1rem;
		font-weight: 400;
		opacity: 0.8;
	}

	main {
		display: flex;
		flex-direction: column;
		gap: 2rem;
	}

	@media (max-width: 768px) {
		.file-organizer {
			padding: 1rem;
		}

		header {
			margin-bottom: 2rem;
			padding: 1.5rem;
		}

		header h1 {
			font-size: 2rem;
		}

		header p {
			font-size: 1rem;
		}
	}
</style>
